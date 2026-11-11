<#
.SYNOPSIS
  Create a Generation 2 Hyper-V VM for Windows Server 2025 lab use.
.EXAMPLE
  .\New-LabVM.ps1 -Name DC01 -IsoPath D:\ISO\ws2025.iso
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Name,
  [Parameter(Mandatory)] [string] $IsoPath,
  [string] $SwitchName = 'LabNet',
  [string] $VmRoot = 'D:\Hyper-V\Lab',
  [int64]  $MemoryStartup = 4GB,
  [int]    $CpuCount = 2,
  [int64]  $DiskSize = 60GB
)
$ErrorActionPreference = 'Stop'

if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
  New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
}

$vhd = Join-Path $VmRoot "$Name\$Name.vhdx"
New-Item -ItemType Directory -Force (Split-Path $vhd) | Out-Null

New-VM -Name $Name -Generation 2 -MemoryStartupBytes $MemoryStartup `
  -NewVHDPath $vhd -NewVHDSizeBytes $DiskSize -SwitchName $SwitchName -Path $VmRoot | Out-Null
Set-VMProcessor -VMName $Name -Count $CpuCount -ExposeVirtualizationExtensions $true
Add-VMDvdDrive -VMName $Name -Path $IsoPath
Set-VMFirmware -VMName $Name -FirstBootDevice (Get-VMDvdDrive -VMName $Name)
Set-VMKeyProtector -VMName $Name -NewLocalKeyProtector
Enable-VMTPM -VMName $Name

Write-Host "Created $Name. Start it with: Start-VM $Name"
