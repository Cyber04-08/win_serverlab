# Lab Setup

## Host prep

Run in an **elevated** PowerShell:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

Reboot when prompted.

## Get the ISO

Download the Windows Server 2025 evaluation ISO from the Microsoft Evaluation Center and place it somewhere outside this repo (e.g. `D:\ISO\`).

## Planned topology

```
Host (Windows 11 + Hyper-V)
 `- Internal vSwitch "LabNet" 192.168.50.0/24
     |- DC01   (AD DS, DNS, DHCP)       192.168.50.10
     |- SRV01  (member server, file/web) 192.168.50.11
     `- CORE01 (Server Core)            192.168.50.12
```

## VirtualBox option

If you're on VirtualBox instead of Hyper-V (the setup used in Lab 02), use this layout:

- Adapter 1: NAT (internet)
- Adapter 2: Internal Network, name `labnet` (domain traffic)
- Subnet: 192.168.10.0/24. DC01 at 192.168.10.10, DHCP scope .100 to .200

Windows 11 clients need EFI, TPM 2.0, and Secure Boot enabled in VirtualBox. Use the ICH9 chipset. Run one VM at a time on a host with limited RAM.

The Hyper-V steps above and `scripts/New-LabVM.ps1` don't apply to this option.
