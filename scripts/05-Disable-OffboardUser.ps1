<#
.SYNOPSIS
    Offboards a departing user: disable, back up and remove groups, stamp
    description, move to the Disabled OU.

.DESCRIPTION
    The account is NOT deleted, so it can be restored if needed. Group
    memberships are saved to a CSV before removal so access can be audited
    or restored.

.EXAMPLE
    .\05-Disable-OffboardUser.ps1 -Identity jcarter -TicketNumber INC-1042 -WhatIf
    .\05-Disable-OffboardUser.ps1 -Identity jcarter -TicketNumber INC-1042
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [string]$TicketNumber,

    [string]$CompanyOU = 'HOMELAB',

    [string]$BackupFolder = (Join-Path $PSScriptRoot 'offboarding-records')
)

Import-Module ActiveDirectory -ErrorAction Stop

try {
    $user = Get-ADUser -Identity $Identity -Properties MemberOf, Description, Department -ErrorAction Stop
}
catch {
    Write-Error "User '$Identity' not found."
    return
}

$domainDN   = (Get-ADDomain).DistinguishedName
$disabledOU = "OU=Users,OU=Disabled,OU=$CompanyOU,$domainDN"
$stamp      = Get-Date -Format 'yyyy-MM-dd'

# 1. Back up group memberships
$groups = foreach ($dn in $user.MemberOf) { Get-ADGroup -Identity $dn }
if (-not (Test-Path $BackupFolder)) { New-Item -Path $BackupFolder -ItemType Directory | Out-Null }
$backupFile = Join-Path $BackupFolder "$($user.SamAccountName)-groups-$stamp.csv"

if ($PSCmdlet.ShouldProcess($backupFile, 'Save group memberships')) {
    $groups | Select-Object @{ n = 'User'; e = { $user.SamAccountName } }, Name, GroupCategory, GroupScope, DistinguishedName |
        Export-Csv -Path $backupFile -NoTypeInformation
    Write-Host "Saved $(@($groups).Count) group membership(s) to $backupFile"
}

# 2. Disable the account
if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable account')) {
    Disable-ADAccount -Identity $user
    Write-Host "Disabled $($user.SamAccountName)" -ForegroundColor Green
}

# 3. Remove group memberships (Domain Users is the primary group and isn't in MemberOf)
foreach ($g in $groups) {
    if ($PSCmdlet.ShouldProcess("$($g.Name)", "Remove $($user.SamAccountName)")) {
        Remove-ADGroupMember -Identity $g -Members $user -Confirm:$false
        Write-Host "  removed from $($g.Name)"
    }
}

# 4. Stamp description so anyone looking at the account knows why it's disabled
$newDescription = "Disabled $stamp - $TicketNumber - by $env:USERNAME (was: $($user.Department))"
if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Set description '$newDescription'")) {
    Set-ADUser -Identity $user -Description $newDescription
}

# 5. Move to Disabled OU
if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Move to $disabledOU")) {
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU
    Write-Host "Moved to $disabledOU" -ForegroundColor Green
}

Write-Host "`nOffboarding complete for $($user.Name). Next: remind manager about mailbox/file handover." -ForegroundColor Cyan
