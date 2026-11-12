# Server Core vs Desktop Experience

## What I did and why I have two VMs

I originally meant to install the **Desktop Experience**. In the VirtualBox wizard I left **OS Edition** on "Windows Server 2025 Standard Evaluation", which is the **Server Core** option. The Desktop Experience is the separate entry ending in "(Desktop Experience)". I only noticed when the VM booted straight into SConfig instead of a desktop.

You can't convert between the two in place on Server 2016 and later, so I built a second VM with the right edition.

| VM | Edition | Disk | Purpose |
|----|---------|------|---------|
| `winserver25` | Standard Evaluation (**Server Core**) | 50 GB VHD | Keeping it. I'll use it later for PowerShell and remote management practice. |
| `winserver25_gui` | Standard Evaluation (**Desktop Experience**) | 50 GB VDI | Main VM for learning with the GUI (Server Manager). |

I'm **not deleting the Core VM**. The mistake turned into a useful second machine.

Screenshots: [labs/01-install-and-baseline/screenshots](../labs/01-install-and-baseline/screenshots)

## Key differences

| | Server Core | Desktop Experience |
|---|---|---|
| Interface | Command line (SConfig, PowerShell) | Full desktop and Server Manager |
| Footprint | Smaller disk and RAM use | Larger |
| Attack surface | Smaller, fewer components to patch | Larger |
| Reboots for patching | Usually fewer | More |
| Best for | Production roles, automation, remote management | Learning, tools that need a GUI |
| Managed from | Remote tools, PowerShell, Windows Admin Center, RSAT | Locally or remotely |

## Gotchas

- **No in-place switch.** Since Server 2016 you can't add or remove the GUI on an existing install. You have to reinstall.
- **Check the edition before finishing the wizard.** The Core entry has no "(Desktop Experience)" suffix.
- VirtualBox labels Server 2025 as "Windows Server 2022 (64-bit)". That's expected.
- SConfig opens automatically on Core. To stop it: `Set-SConfig -AutoLaunch $false`.

## To do later

- [ ] Compare footprint of both VMs (disk used, idle RAM, running services)
- [ ] Manage the Core VM from the Desktop Experience VM (Server Manager, remote PowerShell)
- [ ] Try Windows Admin Center against both
