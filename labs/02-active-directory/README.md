# Lab 02: Active Directory

## Goals
- Promote a Desktop Experience server to a domain controller for a new forest
- Run DNS and DHCP on the DC
- Join clients and check the setup with standard tools

## Environment
- Hypervisor: Oracle VirtualBox (this repo's Hyper-V script is not used for this track)
- Host: Windows 11
- DC01: `winserver25_gui` (Desktop Experience), 4 GB RAM, 3 vCPU, 60 GB dynamic VDI
- Clients: Ubuntu VM (realmd/sssd), Windows 11 Pro VM (planned)

## Network plan

| Item | Value |
|---|---|
| Lab subnet | 192.168.10.0/24 |
| DC01 static IP | 192.168.10.10 (DNS points to itself, no gateway on labnet) |
| DHCP scope | `labnet-scope`, 192.168.10.100 to 192.168.10.200 |
| DHCP options | 006 DNS = 192.168.10.10, 015 domain = nwane.local |
| Domain | nwane.local (NetBIOS NWANE) |

Adapter 1 is NAT for internet. Adapter 2 is an Internal Network named `labnet` for domain traffic.

## Steps

| # | Step | Status |
|---|---|---|
| 1 | VM setup, Guest Additions | Done |
| 2 | Rename to DC01, static IP on labnet | Done |
| 3 | Install AD DS, new forest `nwane.local` | Done |
| 4 | Install DHCP, authorize, create scope and options | Done |
| 5 | Verify AD, DNS, DHCP (see below) | In progress |
| 6 | Join Ubuntu client | In progress (adapter 2 and netplan) |
| 7 | Join Windows 11 client | Planned |
| 8 | Named domain admin, disable built-in Administrator | Planned |

## Log

### 2026-11-13
- Renamed the server to DC01. I typed the name into the Computer description field first, then fixed it under Change... in System Properties.
- Installed AD DS and promoted to a new forest. I used `nwane.local` for the domain name. The "authoritative parent zone" DNS warning is expected in an isolated lab.
- Installed DHCP and authorized it in AD. The scope didn't exist after the role install, so `Get-DhcpServerv4Scope` returned nothing and the option lookup failed with error 20005. Creating the scope with `Add-DhcpServerv4Scope` fixed it.
- Options confirmed: 006 DNS = 192.168.10.10, 015 = nwane.local, 051 lease = 8 days.
- Ubuntu client: first boot showed only the NAT interface (enp0s3). The labnet adapter wasn't enabled yet. Enabling it and adding a netplan DHCP config is the next step.
- Host froze when two 4 GB VMs ran at the same time. I now run one VM at a time while I configure.

## Verification

| Check | Command | Result |
|---|---|---|
| Domain info | `Get-ADDomain` | Confirm after reboot |
| Services | `Get-Service NTDS, DNS, Netlogon, KDC` | Confirm |
| Domain controller health | `dcdiag /v` | Pending |
| DNS | `nslookup nwane.local` | Pending |
| DHCP server in AD | `Get-DhcpServerInDC` | Pass: dc01.nwane.local at 192.168.10.10 |
| DHCP scope | `Get-DhcpServerv4Scope` | Pass: labnet-scope, Active |
| DHCP options | `Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0` | Pass: 006, 015, 051 |

## Open questions
- Confirm the exact edition and version with `(Get-CimInstance Win32_OperatingSystem).Caption`. The VirtualBox label says 2022, but the wizard showed 2025 functional levels.
- Run `dcdiag /v` and record which tests fail before deciding whether they matter.
