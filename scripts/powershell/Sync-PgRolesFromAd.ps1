<#
.SYNOPSIS
    Синхронизирует роли PostgreSQL с группами AD: создаёт роли для новых участников и отзывает у вышедших из группы.
.DESCRIPTION
    Генерирует SQL и, если не указан -WhatIf, применяет его через psql. Роли входят в ad_users
    (в pg_hba.conf для них включена LDAP-аутентификация). Пароли в PostgreSQL не хранятся.
.EXAMPLE
    ./Sync-PgRolesFromAd.ps1 -WhatIf          # только показать изменения
    ./Sync-PgRolesFromAd.ps1 -DbHost pg-rw.lab.local
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DbHost = 'pg-rw.lab.local',
    [string]$Database = 'shop',
    [string]$AdminUser = 'postgres',
    [hashtable]$GroupMap = @{ pg_dba = 'support_dba'; pg_readonly = 'support_ro' }
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SafeRoleName([string]$sam) {
    # SamAccountName попадает в SQL как идентификатор — допускаем только безопасные символы
    if ($sam -notmatch '^[a-z][a-z0-9_.]{0,62}$') { throw "Недопустимое имя учётной записи: '$sam'" }
    return $sam
}

$sql = [System.Collections.Generic.List[string]]::new()
foreach ($adGroup in $GroupMap.Keys) {
    $pgGroup = $GroupMap[$adGroup]
    $members = Get-ADGroupMember -Identity $adGroup -Recursive | Get-ADUser | Where-Object Enabled |
        ForEach-Object { Get-SafeRoleName $_.SamAccountName.ToLower() }

    foreach ($m in $members) {
        $sql.Add("DO `$`$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$m') THEN CREATE ROLE ""$m"" LOGIN; END IF; END `$`$;")
        $sql.Add("GRANT $pgGroup TO ""$m"";")
    }
    # отзыв доступа у тех, кого убрали из AD-группы
    $list = if ($members) { ($members | ForEach-Object { "'$_'" }) -join ',' } else { "''" }
    $sql.Add(@"
DO `$`$ DECLARE r record; BEGIN
  FOR r IN SELECT m.rolname FROM pg_auth_members am JOIN pg_roles m ON m.oid = am.member
           JOIN pg_roles g ON g.oid = am.roleid
           WHERE g.rolname = '$pgGroup' AND m.rolname NOT IN ($list) AND m.rolcanlogin
  LOOP EXECUTE format('REVOKE $pgGroup FROM %I', r.rolname); END LOOP;
END `$`$;
"@)
}

$script = $sql -join "`n"
if ($PSCmdlet.ShouldProcess("$DbHost/$Database", "Применить $($sql.Count) SQL-блоков")) {
    $script | psql -X -v ON_ERROR_STOP=1 -h $DbHost -U $AdminUser -d $Database
    if ($LASTEXITCODE -ne 0) { throw "psql завершился с кодом $LASTEXITCODE" }
}
else {
    Write-Output $script
}
