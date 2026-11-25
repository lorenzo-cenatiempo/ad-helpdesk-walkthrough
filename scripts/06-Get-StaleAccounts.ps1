<#
.SYNOPSIS
    Reports user and computer accounts that haven't logged on in N days,
    plus users whose passwords never expire. Read-only.

.DESCRIPTION
    Uses LastLogonTimestamp, which replicates between DCs but can lag by up
    to ~14 days, so it's good for "stale for 90 days", not "logged in today".
    Accounts that have never logged on are included if they were created
    more than N days ago.

.EXAMPLE
    .\06-Get-StaleAccounts.ps1
    .\06-Get-StaleAccounts.ps1 -DaysInactive 60 -ExportPath C:\Reports
#>
[CmdletBinding()]
param(
    [int]$DaysInactive = 90,
    [string]$ExportPath
)

Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$DaysInactive)

function Test-Stale($obj) {
    if ($obj.LastLogonDate) { return $obj.LastLogonDate -lt $cutoff }
    return $obj.whenCreated -lt $cutoff   # never logged on, and not brand-new
}

$staleUsers = Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonDate, whenCreated, Department |
    Where-Object { Test-Stale $_ } |
    Select-Object Name, SamAccountName, Department,
        @{ n = 'LastLogon'; e = { if ($_.LastLogonDate) { $_.LastLogonDate } else { 'Never' } } },
        whenCreated, DistinguishedName |
    Sort-Object Name

$staleComputers = Get-ADComputer -Filter 'Enabled -eq $true' -Properties LastLogonDate, whenCreated, OperatingSystem |
    Where-Object { Test-Stale $_ } |
    Select-Object Name, OperatingSystem,
        @{ n = 'LastLogon'; e = { if ($_.LastLogonDate) { $_.LastLogonDate } else { 'Never' } } },
        whenCreated, DistinguishedName |
    Sort-Object Name

$neverExpire = Get-ADUser -Filter 'Enabled -eq $true -and PasswordNeverExpires -eq $true' -Properties PasswordNeverExpires |
    Select-Object Name, SamAccountName, DistinguishedName

Write-Host "`n=== Enabled users inactive $DaysInactive+ days: $(@($staleUsers).Count) ===" -ForegroundColor Cyan
$staleUsers | Format-Table Name, SamAccountName, Department, LastLogon -AutoSize

Write-Host "=== Enabled computers inactive $DaysInactive+ days: $(@($staleComputers).Count) ===" -ForegroundColor Cyan
$staleComputers | Format-Table Name, OperatingSystem, LastLogon -AutoSize

Write-Host "=== Users with 'password never expires': $(@($neverExpire).Count) ===" -ForegroundColor Cyan
$neverExpire | Format-Table Name, SamAccountName -AutoSize

if ($ExportPath) {
    if (-not (Test-Path $ExportPath)) { New-Item $ExportPath -ItemType Directory | Out-Null }
    $date = Get-Date -Format yyyyMMdd
    $staleUsers     | Export-Csv (Join-Path $ExportPath "stale-users-$date.csv")     -NoTypeInformation
    $staleComputers | Export-Csv (Join-Path $ExportPath "stale-computers-$date.csv") -NoTypeInformation
    $neverExpire    | Export-Csv (Join-Path $ExportPath "pwd-never-expires-$date.csv") -NoTypeInformation
    Write-Host "Reports exported to $ExportPath" -ForegroundColor Green
}
