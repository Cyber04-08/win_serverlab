# Lab 02: Active Directory

## Goals
- Promote a Desktop Experience server to a domain controller for a new forest
- Run DNS and DHCP on the DC
- Join clients and check the setup with standard tools

## Environment
- Hypervisor: Oracle VirtualBox (this repo's Hyper-V script is not used for this track)
- Host: Windows 11
- DC01: `winserver25_gui`, Windows Server 2025 Standard Evaluation (Desktop Experience), 4 GB RAM, 3 vCPU, 60 GB dynamic VDI
- Clients: five Windows 11 Pro VMs, `WIN11-01` to `WIN11-05`

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
| 5 | Verify AD, DNS, DHCP (see below) | Done |
| 6 | Build and join Windows 11 client | Done |
| 7 | Named domain admin, disable built-in Administrator | Done |
| 8 | Clone the client and join four more (`WIN11-02` to `WIN11-05`) | Done |
| 9 | Reverse lookup zone and PTR record for DC01 | Done |

## Log

### 2026-11-13
- Renamed the server to DC01. I typed the name into the Computer description field first, then fixed it under Change... in System Properties.
- Installed AD DS and promoted to a new forest. I used `nwane.local` for the domain name. The "authoritative parent zone" DNS warning is expected in an isolated lab.
- Installed DHCP and authorized it in AD. The scope didn't exist after the role install, so `Get-DhcpServerv4Scope` returned nothing and the option lookup failed with error 20005. Creating the scope with `Add-DhcpServerv4Scope` fixed it.
- Options confirmed: 006 DNS = 192.168.10.10, 015 = nwane.local, 051 lease = 8 days.
- Host froze when two 4 GB VMs ran at the same time. I now run one VM at a time while I configure. Later both ran together without a freeze.
- Windows 11 client first boot: black screen, then UEFI reported "Not Found" for both the CD and the disk. The ISO had not been mounted in the optical drive. Mounting it and retrying fixed it.
- DNS: `nslookup nwane.local` from the client returned three addresses, including DC01's NAT address `10.0.2.15` and an IPv6 address from the NAT adapter, which the client can't reach. The DNS zone only held `192.168.10.10`, so the extra answers were cached. `ipconfig /flushdns` fixed it. To keep it from returning, I disabled DNS registration on DC01's NAT adapter and limited the DNS server to listen only on 192.168.10.10.
- Time: the client showed a time 2 hours behind the host. That was a time zone difference (Pacific vs Central), not drift. `(Get-Date).ToUniversalTime()` matched DC01 to within a minute. `w32tm /resync` failed with "The service has not been started" because the Windows Time service wasn't running.

### 2026-11-14
- Ran `dcdiag`. Every test passed except SystemLog and DFSREvent, which scan the last 24 hours of event logs. The SystemLog entries were all from the first minutes after boot: disk write cache warnings, a DNS lookup that timed out before the DNS service finished starting, WinRM SPN and DHCPv6 warnings, the NtpClient "no time source" warning, and sign-in and shutdown noise. None point to an AD, DNS, or replication fault. A re-run after the events age out should come back clean.
- Pointed DC01's time source at `time.windows.com` with `w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:yes /update`, then restarted the Windows Time service. This clears the NtpClient warning.
- Created the named admin `rickky.adm` (Ricky Admin) with `New-ADUser` and added it to Domain Admins. Signed in with it on DC01 and on WIN11-01, then disabled the built-in Administrator (`Enabled: False`). The first `New-ADUser` attempt failed on a typo in the `-UserPrincipalName` parameter name, so nothing was created until the retry.
- The AD cmdlets (`Get-ADUser` and the rest) only exist on DC01. On the client they fail with "not recognized" until RSAT is installed.

### 2026-11-15
- Built the other four clients by cloning a freshly installed Windows 11 VM that had only the local account name and the `labnet` adapter configured. The source VM was fully shut down first. Each clone was a Full Clone of the current machine state with **Generate new MAC addresses for all network adapters**.
- On each clone: `Rename-Computer -NewName WIN11-0X -Restart`, then `Add-Computer -DomainName nwane.local -Credential <admin account> -Restart`. All four joined and got leases from the DHCP scope.
- `nslookup` on a client showed `Default Server: UnKnown` for 192.168.10.10. DNS had no reverse lookup zone, so the IP could not be mapped back to a name. I created an Active Directory-integrated reverse zone for 192.168.10.0/24 (`10.168.192.in-addr.arpa`, replicated to all DNS servers in the domain, secure dynamic updates only) and ran `ipconfig /registerdns` on DC01. After that, `nslookup DC01.nwane.local` and `nslookup 192.168.10.10` both return `DC01.nwane.local` at 192.168.10.10.
- Re-ran `dcdiag` after the boot-time events aged out. Every test passed, including SystemLog and DFSREvent, which failed on 11-14. DFSREvent and SystemLog still print warning text (SYSVOL-share events from the first boots, and an unexpected-shutdown entry from powering the VM off without a clean shutdown) but report passed. Enterprise tests on `nwane.local` (LocatorCheck, Intersite) and all partition tests passed. Going forward I shut DC01 down from inside Windows.

## Windows 11 client

VM settings (VirtualBox New Virtual Machine wizard):

| Setting | Value |
|---|---|
| VM name | win11client (a `win11-client` VM also exists; remove the duplicate or note which one you use) |
| ISO | Windows11_Client_x64_en-us_26300_9457.iso |
| Edition | Windows 11 Pro |
| Unattended install | On, with a local user account. Wizard host name `win11client` (Windows came up as `Client`, renamed to `WIN11-01` during the domain join), domain name field changed from the default `myguest.virtualbox.org` to `nwane.local` |
| Guest Additions | Unticked in the wizard, installed manually after setup |
| Hardware | 4096 MB RAM, 2 CPUs, EFI on |
| Disk | New dynamically allocated 80 GB VDI (not the Ubuntu disk) |
| Adapters | Adapter 1 on Internal Network `labnet` only (no NAT, so no internet) |

Notes:
- Black screen at first boot was caused by the Windows ISO not being mounted in the optical drive. The UEFI firmware reported "Not Found" for both the CD and the hard disk, and the DVD field in the boot dialog was empty. Mounting the ISO and retrying the boot fixed it.
- Mouse pointer: the host's pointer showed in the VM window and the guest's pointer was missing. Installing Guest Additions fixed it.
- Windows setup stopped on "Let's connect you to a network" because `labnet` has no internet. I bypassed it with `oobe\bypassnro` and created a local account.
- Before the join, `ipconfig /all` showed `169.254.x.x` while DC01 was off. After DC01 started, the client got a lease from DHCP (see Verification).
- Joined `nwane.local` on 2026-11-13 ("Welcome to the nwane.local domain"). `systeminfo` reports `Domain: nwane.local`. Windows 11 Pro 26H2, build 26300.9457.
- After the restart I signed in as `NWANE\Administrator`. `whoami` returned `nwane\administrator`, and the computer `WIN11-01` appears under Computers in Active Directory Users and Computers on DC01.

## Verification

| Check | Command | Result |
|---|---|---|
| Domain info | `Get-ADDomain` | Pass: nwane.local, NetBIOS NWANE, Windows2025Domain mode |
| Services | `Get-Service NTDS, DNS, Netlogon, KDC` | Pass: running |
| OS edition | `(Get-CimInstance Win32_OperatingSystem).Caption` | Windows Server 2025 Standard Evaluation |
| Domain controller health | `dcdiag` | Pass on all tests as of 2026-11-15 (SystemLog and DFSREvent failed on 2026-11-14 from boot-time log events) |
| Named admin | `whoami /groups` as `rickky.adm` | Pass: member of Domain Admins |
| Built-in Administrator | `Get-ADUser Administrator \| Select Name, Enabled` | Pass: Enabled False |
| DHCP server in AD | `Get-DhcpServerInDC` | Pass: dc01.nwane.local at 192.168.10.10 |
| DHCP scope | `Get-DhcpServerv4Scope` | Pass: labnet-scope, Active |
| DHCP options | `Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0` | Pass: 006, 015, 051 |
| Client DHCP lease | `ipconfig /all` on the client | Pass: 192.168.10.101, DHCP server and DNS 192.168.10.10, suffix nwane.local, 8-day lease |
| DNS from client | `nslookup nwane.local` | Pass after flushing the cache: 192.168.10.10 only |
| Domain join | `systeminfo \| findstr /B /C:"Domain"` | Pass: Domain nwane.local |
| Domain sign-in | `whoami` on the client | Pass: nwane\administrator |
| DC locator | `nltest /dsgetdc:nwane.local` | Pass: DC01.nwane.local at 192.168.10.10, flags include PDC GC DS KDC TIMESERV WRITABLE |
| Computer object | Active Directory Users and Computers > Computers | Pass: WIN11-01 listed |
| All clients in AD | Active Directory Users and Computers > Computers | Pass: WIN11-01 to WIN11-05 listed |
| All client leases | `Get-DhcpServerv4Lease -ScopeId 192.168.10.0` | Pass: five active leases, 192.168.10.101 to .105, 8-day expiry |
| Reverse DNS | `nslookup 192.168.10.10` | Pass: DC01.nwane.local (was "UnKnown" before the reverse zone) |
| Forward DNS | `nslookup DC01.nwane.local` | Pass: 192.168.10.10 only |

## Open items
- Check reverse lookups from every client, not just one.
- Take snapshots of DC01 and WIN11-01 at this known-good state.

## Screenshots

| File | Shows |
|---|---|
| [ad-computers.png](screenshots/ad-computers.png) | WIN11-01 to WIN11-05 under Computers |
| [dhcp-leases.png](screenshots/dhcp-leases.png) | Five active leases with `nwane.local` hostnames |
| [client-nslookup-before.png](screenshots/client-nslookup-before.png) | Client check: domain sign-in, `nwane.local`, and `nslookup` showing "UnKnown" before the reverse zone |
| [nslookup-name-after.png](screenshots/nslookup-name-after.png) | `nslookup DC01.nwane.local` after the fix |
| [nslookup-reverse-after.png](screenshots/nslookup-reverse-after.png) | `nslookup 192.168.10.10` after the fix |
| [dcdiag-1.png](screenshots/dcdiag-1.png), [dcdiag-2.png](screenshots/dcdiag-2.png), [dcdiag-3.png](screenshots/dcdiag-3.png) | `dcdiag` on 2026-11-15: all tests passed |
