<#
.SYNOPSIS
    Builds the lab's OU structure and department groups.

.DESCRIPTION
    Creates the HOMELAB OU tree (Users by department, Computers, Groups,
    Service Accounts, Disabled) with accidental-deletion protection, plus
    one global security group per department, a help desk group and an
    all-staff distribution group. Safe to run more than once: existing
    objects are skipped.

.EXAMPLE
    .\01-Build-OUStructure.ps1 -WhatIf
    .\01-Build-OUStructure.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CompanyOU = 'HOMELAB',
    [string[]]$Departments = @('Finance', 'HR', 'IT', 'Marketing', 'Sales')
)

Import-Module ActiveDirectory -ErrorAction Stop

$domainDN = (Get-ADDomain).DistinguishedName
$rootDN   = "OU=$CompanyOU,$domainDN"

function New-OUIfMissing {
    param([string]$Name, [string]$Path)
    $dn = "OU=$Name,$Path"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue) {
        Write-Host "  exists : $dn" -ForegroundColor DarkGray
    }
    elseif ($PSCmdlet.ShouldProcess($dn, 'Create OU')) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Host "  created: $dn" -ForegroundColor Green
    }
}

function New-GroupIfMissing {
    param([string]$Name, [string]$Path, [string]$Category, [string]$Description)
    if (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue) {
        Write-Host "  exists : $Name" -ForegroundColor DarkGray
    }
    elseif ($PSCmdlet.ShouldProcess($Name, "Create $Category group")) {
        New-ADGroup -Name $Name -SamAccountName $Name -GroupScope Global `
            -GroupCategory $Category -Path $Path -Description $Description
        Write-Host "  created: $Name" -ForegroundColor Green
    }
}

Write-Host "Building OU structure under $rootDN" -ForegroundColor Cyan

New-OUIfMissing -Name $CompanyOU -Path $domainDN

foreach ($ou in 'Users', 'Computers', 'Groups', 'Service Accounts', 'Disabled') {
    New-OUIfMissing -Name $ou -Path $rootDN
}
foreach ($dept in $Departments) {
    New-OUIfMissing -Name $dept -Path "OU=Users,$rootDN"
}
foreach ($ou in 'Workstations', 'Laptops') {
    New-OUIfMissing -Name $ou -Path "OU=Computers,$rootDN"
}
foreach ($ou in 'Security', 'Distribution') {
    New-OUIfMissing -Name $ou -Path "OU=Groups,$rootDN"
}
foreach ($ou in 'Users', 'Computers') {
    New-OUIfMissing -Name $ou -Path "OU=Disabled,$rootDN"
}

Write-Host "Creating groups" -ForegroundColor Cyan
$securityPath     = "OU=Security,OU=Groups,$rootDN"
$distributionPath = "OU=Distribution,OU=Groups,$rootDN"

foreach ($dept in $Departments) {
    New-GroupIfMissing -Name "SG-$dept-Users" -Path $securityPath -Category Security `
        -Description "All $dept department staff"
}
New-GroupIfMissing -Name 'SG-IT-HelpDesk' -Path $securityPath -Category Security `
    -Description 'Help desk technicians - delegated password reset/unlock'
New-GroupIfMissing -Name 'DL-AllStaff' -Path $distributionPath -Category Distribution `
    -Description 'All staff distribution list'

Write-Host "Done." -ForegroundColor Cyan
