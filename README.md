# win_serverlab

A hands-on lab for exploring, learning, and tinkering with **Windows Server 2025**.

Everything here is meant to be reproducible: scripts to build the lab, notes on what I learned, and write-ups of each experiment.

## Lab tracks

| # | Track | Topics | Status |
|---|-------|--------|--------|
| 01 | [Install and baseline](labs/01-install-and-baseline) | Evaluation ISO, VM creation, Server Core vs Desktop Experience, initial config | In progress |
| 02 | [Active Directory](labs/02-active-directory) | AD DS, domain join, GPO, new 2025 features (e.g. 32k database page size, DC-level improvements) | Done (domain, DHCP, 5 joined clients, DNS); GPO not started |
| 03 | [Networking, DNS, DHCP](labs/03-networking-dns-dhcp) | DNS, DHCP, SMB over QUIC, networking changes in 2025 | In progress (DNS and DHCP done in Lab 02; SMB over QUIC and 2025 changes not started) |
| 04 | [Hyper-V and containers](labs/04-hyper-v-and-containers) | Nested virtualization, Hyper-V, Windows containers, GPU partitioning | Planned |
| 05 | [Security hardening](labs/05-security-hardening) | Baselines, Defender, Credential Guard, delegated managed service accounts (dMSA) | Planned |

## Repo layout

```
docs/     Lab design, topology, how to set up the host
labs/     One folder per track, each with a README and scripts
scripts/  Reusable PowerShell helpers (VM builders, config helpers)
notes/    Scratch notes and things learned
```

## Requirements

- A host that can run several VMs (Lab 02 runs on VirtualBox; any hypervisor works)
- Windows Server 2025 evaluation ISO (180-day, from the Microsoft Evaluation Center)
- PowerShell 7+

## Getting started

1. Read [docs/lab-setup.md](docs/lab-setup.md)
2. Run `scripts/New-LabVM.ps1` to create a VM
3. Work through the tracks in order, or jump to whichever interests you

## Safety

This is a lab. Don't commit passwords, product keys, ISO files, or VHDX files. The `.gitignore` blocks the common ones.

## License

MIT
