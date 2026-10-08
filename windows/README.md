# Windows Host Prep (not Nix-managed)

This directory holds plain preparation scripts for bootstrapping a
**brand-new Windows 10/11 machine that does not yet have WSL installed
at all**, up to the point where this flake's own `README.md` takes
over inside a Debian WSL guest.

Nothing here is managed by Home Manager or the flake. These are
one-time (or idempotent re-run) host-prep scripts, kept in version
control for convenience only.

## Flow

### 1. On Windows: `bootstrap-windows.ps1`

Run from a normal (non-elevated) PowerShell window:

```powershell
.\bootstrap-windows.ps1
```

The script always checks status first in whatever context you launched
it from -- no UAC prompt yet. Checking whether WSL/VirtualMachinePlatform
are enabled, whether `Debian` is registered, and whether Chocolatey and
its packages are installed all work fine without admin rights. **Only
if that check finds real pending work** does the script request
elevation (a UAC prompt -- any administrator account's credentials
work, you do not need to be logged into an admin account yourself) for
the admin-required steps (enabling features, `wsl --install -d Debian`,
Chocolatey and its packages). It then drops back to your normal user
context to install Scoop (Scoop's own installer advises against
running elevated).

This means: on a fully-provisioned machine, re-running this script
prints only `[OK]` lines and **never triggers a UAC prompt at all**.
If you cancel the UAC prompt, or no admin credentials are available,
the script reports that plainly and exits -- it does not retry silently
or fall back to doing nothing while claiming success.

What it does, in order:

1. Enables the `Microsoft-Windows-Subsystem-Linux` and
   `VirtualMachinePlatform` optional Windows features if not already
   enabled.
   - **If this is the first time either feature is enabled, the
     script stops here and asks you to reboot.** Re-run the script
     after rebooting; it will skip this step (already `Enabled`) and
     continue.
2. Reports (informational only, never blocking) whether hardware
   virtualization (Intel VT-x / AMD-V) appears enabled in firmware.
   Windows cannot enable this for you -- if WSL2 later fails to start
   a VM, enable virtualization in your BIOS/UEFI setup yourself.
3. Installs the `Debian` WSL distro via `wsl --install -d Debian`, if
   a distro named `Debian` isn't already registered (checked via
   `wsl --list --quiet`). An existing `Debian` distro is never
   reinstalled, reset, or unregistered.
4. Installs Chocolatey, if not already present.
5. Installs `microsoft-windows-terminal` and `podman-desktop` via
   Chocolatey, if not already installed.
6. Installs Scoop, if not already present (run in the non-elevated
   user context).

After this script finishes, launch **Podman Desktop** once and follow
its first-run onboarding to create and start its WSL2 machine -- that
GUI step isn't automated here.

### 2. Inside the new Debian WSL distro: `setup-wsl-nix.sh`

Open the new `Debian` distro (Start menu, or `wsl -d Debian`), then:

```bash
bash setup-wsl-nix.sh
```

(You'll need to get this file into the WSL guest first -- e.g. `git
clone` this repo inside WSL, or copy the file over. The WSL filesystem
can also reach your Windows files under `/mnt/c/...` if you'd rather
run it from there directly.)

This script is idempotent and installs, only if missing:

1. **Determinate Nix** (`install.determinate.systems`), non-interactively.
2. Flakes support (`experimental-features = nix-command flakes`) in
   `~/.config/nix/nix.conf`, if not already present. [Unverified]:
   Determinate's own docs confirm they write `/etc/nix/nix.conf` with
   "carefully chosen values" but do not document flakes being among
   them by default, so this is checked and added explicitly rather
   than assumed.
3. **Linuxbrew** (Homebrew on Linux) at its documented prefix
   `/home/linuxbrew/.linuxbrew`, including the apt prerequisites listed
   in Homebrew's own docs (`build-essential procps curl file git`) and
   the `brew shellenv` line in `~/.bashrc`.

After this script succeeds, continue with the main flake's
`README.md`: clone this repo to `~/.config/nix`, run
`sudo ~/bin/bootstrap-apt.sh`, then `nix run ~/.config/nix#hm -- switch`.

## Known Gaps and Honest Caveats

A few things could not be verified against official Microsoft/Scoop
documentation and are called out in comments at the point they matter,
rather than silently assumed:

- Microsoft's reference docs for `Get-WindowsOptionalFeature` do not
  enumerate the exact `.State` string values; this script compares
  against the literal `'Enabled'`, the documented convention in
  practice.
- There is no single documented, universal "pending reboot" registry
  check. Instead, the script tracks whether it changed a feature
  during the current run and treats that as the trigger to stop and
  ask for a reboot -- it does not attempt to detect reboot-pending
  state left over from some unrelated prior action.
- Scoop's official site did not expose a bucket/package entry for
  Windows Terminal that could be verified through documentation
  extraction, so Windows Terminal is installed via Chocolatey only
  (`microsoft-windows-terminal`), not via Scoop.
- Podman Desktop's Windows-specific first-run machine setup (`podman
  machine init` / `podman machine start`) is a GUI onboarding flow per
  its own docs, not scripted here.

## Why These Files Aren't Nix-Managed

This flake targets `aarch64-linux` Home Manager profiles for an
already-running Linux environment. These two scripts instead prepare
a Windows host and a not-yet-configured WSL guest to reach that
starting point -- there is no Home Manager module to express "enable
a Windows optional feature" or "run the Windows installer for
Chocolatey." They are plain, version-controlled scripts for
convenience and repeatability, not flake outputs.
