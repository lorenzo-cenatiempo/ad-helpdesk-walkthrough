<#
.SYNOPSIS
    Adds/removes a user to/from a group, or reports a user's group memberships.

.EXAMPLE
    .\07-Manage-GroupMembership.ps1 -Action Report -Identity abrooks
    .\07-Manage-GroupMembership.ps1 -Action Add    -Identity abrooks -Group SG-Finance-Users
    .\07-Manage-GroupMembership.ps1 -Action Remove -Identity abrooks -Group SG-Sales-Users
    .\07-Manage-GroupMembership.ps1 -Action Members -Group SG-Finance-Users
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Add', 'Remove', 'Report', 'Members')]
    [string]$Action,

    [string]$Identity,

    [string]$Group
)

Import-Module ActiveDirectory -ErrorAction Stop

if ($Action -in 'Add', 'Remove', 'Report' -and -not $Identity) { throw "-Identity is required for -Action $Action" }
if ($Action -in 'Add', 'Remove', 'Members' -and -not $Group)   { throw "-Group is required for -Action $Action" }

switch ($Action) {
    'Report' {
        $user = Get-ADUser -Identity $Identity -Properties Department, DistinguishedName
        Write-Host "$($user.Name) ($($user.SamAccountName)) - $($user.Department)" -ForegroundColor Cyan
        Write-Host "OU: $($user.DistinguishedName -replace '^CN=[^,]+,', '')"
        # Get-ADPrincipalGroupMembership includes the primary group (Domain Users)
        Get-ADPrincipalGroupMembership -Identity $user |
            Select-Object Name, GroupCategory, GroupScope |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    'Members' {
        Get-ADGroupMember -Identity $Group |
            Select-Object Name, SamAccountName, objectClass |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    'Add' {
        $already = Get-ADGroupMember -Identity $Group | Where-Object SamAccountName -eq $Identity
        if ($already) {
            Write-Host "$Identity is already a member of $Group." -ForegroundColor Yellow
        }
        elseif ($PSCmdlet.ShouldProcess($Group, "Add $Identity")) {
            Add-ADGroupMember -Identity $Group -Members $Identity
            Write-Host "Added $Identity to $Group. User must log off/on for access to apply." -ForegroundColor Green
        }
    }
    'Remove' {
        if ($PSCmdlet.ShouldProcess($Group, "Remove $Identity")) {
            Remove-ADGroupMember -Identity $Group -Members $Identity -Confirm:$false
            Write-Host "Removed $Identity from $Group." -ForegroundColor Green
        }
    }
}
