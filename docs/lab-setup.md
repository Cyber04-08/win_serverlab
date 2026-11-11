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
