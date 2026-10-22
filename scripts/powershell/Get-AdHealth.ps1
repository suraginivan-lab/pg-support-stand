<#
.SYNOPSIS
    Состояние Active Directory для сопровождения PostgreSQL: DC, SRV-записи, группы PG-доступа, заблокированные учётки.
.NOTES
    Требуется модуль RSAT ActiveDirectory и права чтения домена.
#>
[CmdletBinding()]
param(
    [string]$Domain = 'lab.local',
    [string[]]$PgGroups = @('pg_dba', 'pg_readonly')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$dc = Get-ADDomainController -Discover -DomainName $Domain
Write-Host "Контроллер домена: $($dc.HostName) ($($dc.IPv4Address))"

foreach ($name in '_ldap._tcp', '_kerberos._tcp') {
    $r = Resolve-DnsName -Name "$name.$Domain" -Type SRV -ErrorAction SilentlyContinue
    '{0,-18} {1}' -f $name, $(if ($r) { 'OK' } else { 'НЕ НАЙДЕНА' })
}

foreach ($g in $PgGroups) {
    $members = Get-ADGroupMember -Identity $g -Recursive | Get-ADUser -Properties Enabled, LockedOut, PasswordExpired
    Write-Host "`nГруппа $g — участников: $(@($members).Count)"
    $members | Select-Object SamAccountName, Enabled, LockedOut, PasswordExpired | Format-Table -AutoSize
}

$locked = Search-ADAccount -LockedOut -UsersOnly | Select-Object SamAccountName, LockedOut
if ($locked) { Write-Warning 'Заблокированные учётные записи:'; $locked | Format-Table -AutoSize }
