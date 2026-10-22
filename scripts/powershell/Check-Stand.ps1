<#
.SYNOPSIS
    Проверка стенда с Windows-рабочей станции: DNS-записи, доступность портов, запрос к PostgreSQL.
.EXAMPLE
    ./Check-Stand.ps1 -DnsServer 127.0.0.1 -Zone lab.local
#>
[CmdletBinding()]
param(
    [string]$DnsServer = '127.0.0.1',
    [string]$Zone = 'lab.local',
    [string[]]$Hosts = @('pg-primary', 'pg-replica', 'pg-rw', 'pg-ro'),
    [int]$PgPort = 5432
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Result([string]$Name, [bool]$Ok, [string]$Detail) {
    [pscustomobject]@{ Check = $Name; Status = $(if ($Ok) { 'OK' } else { 'CRITICAL' }); Detail = $Detail }
}

$results = @(foreach ($h in $Hosts) {
    $fqdn = "$h.$Zone"
    try {
        $rec = Resolve-DnsName -Name $fqdn -Server $DnsServer -Type A -DnsOnly -ErrorAction Stop |
            Where-Object Type -eq 'A' | Select-Object -First 1
        New-Result "dns:$fqdn" ($null -ne $rec) ($rec.IPAddress)
    }
    catch { New-Result "dns:$fqdn" $false $_.Exception.Message }
})

# SRV-запись сервиса PostgreSQL
try {
    $srv = Resolve-DnsName -Name "_postgresql._tcp.$Zone" -Server $DnsServer -Type SRV -DnsOnly -ErrorAction Stop |
        Where-Object Type -eq 'SRV' | Select-Object -First 1
    $results += New-Result 'dns:SRV postgresql' ($srv.Port -eq $PgPort) "$($srv.NameTarget):$($srv.Port)"
}
catch { $results += New-Result 'dns:SRV postgresql' $false $_.Exception.Message }

# порт PostgreSQL
$tcp = Test-NetConnection -ComputerName "pg-rw.$Zone" -Port $PgPort -WarningAction SilentlyContinue
$results += New-Result "tcp:$PgPort" $tcp.TcpTestSucceeded "pg-rw.$Zone"

$results | Format-Table -AutoSize
if ($results.Status -contains 'CRITICAL') { exit 2 } else { exit 0 }
