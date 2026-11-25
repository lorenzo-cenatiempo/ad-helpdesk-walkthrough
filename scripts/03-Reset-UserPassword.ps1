<#
.SYNOPSIS
    Resets a user's password to a random temporary one, unlocks the account,
    and forces a change at next logon.

.DESCRIPTION
    Help desk password reset. VERIFY THE CALLER'S IDENTITY FIRST.
    The temporary password is shown once on screen and never written to disk.
    Use -PromptForPassword to type your own instead (entered securely).

.EXAMPLE
    .\03-Reset-UserPassword.ps1 -Identity jcarter
    .\03-Reset-UserPassword.ps1 -Identity jcarter -PromptForPassword
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [switch]$PromptForPassword
)

Import-Module ActiveDirectory -ErrorAction Stop

function New-TempPassword {
    param([int]$Length = 14)
    $sets = @('ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnpqrstuvwxyz', '23456789', '!@#$%*?-')
    $all  = -join $sets
    $rng  = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $pick = {
        param($chars)
        $b = New-Object byte[] 4
        $rng.GetBytes($b)
        $chars[[BitConverter]::ToUInt32($b, 0) % $chars.Length]
    }
    $chars = @(foreach ($s in $sets) { & $pick $s })
    while ($chars.Count -lt $Length) { $chars += & $pick $all }
    -join ($chars | Sort-Object { Get-Random })
}

try {
    $user = Get-ADUser -Identity $Identity -Properties LockedOut, Enabled, PasswordLastSet -ErrorAction Stop
}
catch {
    Write-Error "User '$Identity' not found."
    return
}

if (-not $user.Enabled) {
    Write-Warning "$($user.SamAccountName) is DISABLED. Check whether this person has left the company before continuing."
    return
}

if ($PromptForPassword) {
    $secure = Read-Host "New temporary password for $($user.SamAccountName)" -AsSecureString
    $plain  = $null
} else {
    $plain  = New-TempPassword
    $secure = ConvertTo-SecureString $plain -AsPlainText -Force
}

if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Reset password, unlock, require change at logon')) {
    try {
        Set-ADAccountPassword -Identity $user -Reset -NewPassword $secure -ErrorAction Stop
        Set-ADUser -Identity $user -ChangePasswordAtLogon $true
        if ($user.LockedOut) { Unlock-ADAccount -Identity $user }

        Write-Host "Password reset for $($user.Name) ($($user.SamAccountName))." -ForegroundColor Green
        if ($user.LockedOut) { Write-Host "Account was locked and has been unlocked." -ForegroundColor Green }
        if ($plain) {
            Write-Host "Temporary password: " -NoNewline
            Write-Host $plain -ForegroundColor Yellow
            Write-Host "Give this to the user through an approved channel. They must change it at next logon."
        }
    }
    catch {
        # Most common failure: password doesn't meet the domain policy
        Write-Error "Reset failed: $($_.Exception.Message)"
    }
}
