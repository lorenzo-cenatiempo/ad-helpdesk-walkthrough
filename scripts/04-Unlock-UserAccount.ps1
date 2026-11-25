<#
.SYNOPSIS
    Lists locked-out accounts, or unlocks a specific user and shows lockout details.

.EXAMPLE
    .\04-Unlock-UserAccount.ps1 -ListLocked
    .\04-Unlock-UserAccount.ps1 -Identity jcarter
    .\04-Unlock-UserAccount.ps1 -Identity jcarter -ShowLockoutSource
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Unlock')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Unlock')]
    [string]$Identity,

    [Parameter(ParameterSetName = 'Unlock')]
    [switch]$ShowLockoutSource,

    [Parameter(Mandatory, ParameterSetName = 'List')]
    [switch]$ListLocked
)

Import-Module ActiveDirectory -ErrorAction Stop

if ($ListLocked) {
    $locked = Search-ADAccount -LockedOut -UsersOnly |
        Get-ADUser -Properties BadLogonCount, LastBadPasswordAttempt, Department |
        Select-Object Name, SamAccountName, Department, BadLogonCount, LastBadPasswordAttempt
    if ($locked) {
        $locked | Format-Table -AutoSize
    } else {
        Write-Host "No locked-out user accounts." -ForegroundColor Green
    }
    return
}

try {
    $user = Get-ADUser -Identity $Identity -Properties LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordExpired, Enabled -ErrorAction Stop
}
catch {
    Write-Error "User '$Identity' not found."
    return
}

$user | Select-Object Name, SamAccountName, Enabled, LockedOut, PasswordExpired, BadLogonCount, LastBadPasswordAttempt |
    Format-List

if ($ShowLockoutSource) {
    # Event 4740 is logged on the PDC Emulator when an account is locked out
    $pdc = (Get-ADDomain).PDCEmulator
    Write-Host "Recent lockout events for $($user.SamAccountName) on $pdc :" -ForegroundColor Cyan
    try {
        Get-WinEvent -ComputerName $pdc -FilterHashtable @{ LogName = 'Security'; Id = 4740 } -MaxEvents 200 -ErrorAction Stop |
            Where-Object { $_.Properties[0].Value -eq $user.SamAccountName } |
            Select-Object -First 10 TimeCreated, @{ n = 'CallerComputer'; e = { $_.Properties[1].Value } } |
            Format-Table -AutoSize
    }
    catch {
        Write-Warning "No 4740 events found (or no permission to read the Security log)."
    }
}

if (-not $user.LockedOut) {
    Write-Host "$($user.SamAccountName) is not locked out." -ForegroundColor Yellow
    if ($user.PasswordExpired) { Write-Host "But the password has EXPIRED. Use 03-Reset-UserPassword.ps1." -ForegroundColor Yellow }
    if (-not $user.Enabled)    { Write-Host "But the account is DISABLED." -ForegroundColor Yellow }
    return
}

if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Unlock account')) {
    Unlock-ADAccount -Identity $user
    Write-Host "Unlocked $($user.SamAccountName)." -ForegroundColor Green
}
