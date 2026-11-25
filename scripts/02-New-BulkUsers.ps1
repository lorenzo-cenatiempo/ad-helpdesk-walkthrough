<#
.SYNOPSIS
    Creates AD user accounts in bulk from a CSV file (new-hire onboarding).

.DESCRIPTION
    For each row in the CSV:
      - Builds a unique username (first initial + last name, adds a number if taken)
      - Creates the user in OU=<Department>,OU=Users,OU=HOMELAB
      - Sets title, department, office, phone and a random temporary password
      - Forces a password change at next logon
      - Adds the user to SG-<Department>-Users and DL-AllStaff
    A second pass sets each user's Manager (so managers in the same CSV work).
    Temporary passwords are written to a CSV for handoff. Treat that file as
    sensitive and delete it after use.

.PARAMETER CsvPath
    CSV with columns: FirstName, LastName, Department, Title, Manager, Office, Phone

.EXAMPLE
    .\02-New-BulkUsers.ps1 -CsvPath ..\data\new-hires.csv -WhatIf
    .\02-New-BulkUsers.ps1 -CsvPath ..\data\new-hires.csv
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [string]$CompanyOU = 'HOMELAB',

    [string]$OutputPath = (Join-Path $PSScriptRoot "temp-passwords-$(Get-Date -Format yyyyMMdd-HHmmss).csv")
)

Import-Module ActiveDirectory -ErrorAction Stop

function New-TempPassword {
    # 16 chars from a set without look-alikes (0/O, 1/l/I), guaranteed to hit all 4 complexity classes
    param([int]$Length = 16)
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

function Get-UniqueSam {
    param([string]$First, [string]$Last)
    $clean = ($First.Substring(0, 1) + $Last) -replace '[^a-zA-Z0-9]', ''
    $base  = $clean.ToLower()
    if ($base.Length -gt 18) { $base = $base.Substring(0, 18) }   # sAMAccountName max is 20
    $sam = $base
    $n = 2
    while (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        $sam = "$base$n"; $n++
    }
    $sam
}

$domain   = Get-ADDomain
$upnSuffix = $domain.DNSRoot
$rootDN   = "OU=$CompanyOU,$($domain.DistinguishedName)"
$rows     = Import-Csv $CsvPath
$results  = New-Object System.Collections.Generic.List[object]
$created  = @{}   # row index -> sam, for the manager pass

for ($i = 0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    $ouPath = "OU=$($r.Department),OU=Users,$rootDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue)) {
        Write-Warning "Skipping $($r.FirstName) $($r.LastName): OU not found ($ouPath). Run 01-Build-OUStructure.ps1 first."
        continue
    }

    $sam      = Get-UniqueSam -First $r.FirstName -Last $r.LastName
    $display  = "$($r.FirstName) $($r.LastName)"
    $password = New-TempPassword

    if ($PSCmdlet.ShouldProcess("$display ($sam) in $ouPath", 'Create user')) {
        try {
            $params = @{
                Name                  = $display
                GivenName             = $r.FirstName
                Surname               = $r.LastName
                DisplayName           = $display
                SamAccountName        = $sam
                UserPrincipalName     = "$sam@$upnSuffix"
                Path                  = $ouPath
                Title                 = $r.Title
                Department            = $r.Department
                Company               = $CompanyOU
                AccountPassword       = (ConvertTo-SecureString $password -AsPlainText -Force)
                ChangePasswordAtLogon = $true
                Enabled               = $true
            }
            if ($r.Office) { $params.Office          = $r.Office }
            if ($r.Phone)  { $params.OfficePhone     = $r.Phone }

            New-ADUser @params -ErrorAction Stop

            foreach ($g in "SG-$($r.Department)-Users", 'DL-AllStaff') {
                if (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue) {
                    Add-ADGroupMember -Identity $g -Members $sam
                } else {
                    Write-Warning "Group $g not found; $sam not added."
                }
            }

            $created[$i] = $sam
            $results.Add([pscustomobject]@{
                Name = $display; Username = $sam; Department = $r.Department; TempPassword = $password
            })
            Write-Host "Created $sam ($display) in $($r.Department)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to create ${display}: $($_.Exception.Message)"
        }
    }
}

# Second pass: managers (may have been created in the first pass)
foreach ($i in $created.Keys) {
    $mgr = $rows[$i].Manager
    if ([string]::IsNullOrWhiteSpace($mgr)) { continue }
    if (Get-ADUser -Filter "SamAccountName -eq '$mgr'" -ErrorAction SilentlyContinue) {
        Set-ADUser -Identity $created[$i] -Manager $mgr
    } else {
        Write-Warning "Manager '$mgr' not found for $($created[$i])."
    }
}

if ($results.Count -gt 0) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "`n$($results.Count) user(s) created. Temporary passwords saved to:`n  $OutputPath" -ForegroundColor Cyan
    Write-Host "Hand these over securely, then delete the file." -ForegroundColor Yellow
}
