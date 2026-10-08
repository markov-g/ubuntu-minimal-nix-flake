#Requires -Version 5.1
<#
.SYNOPSIS
  Idempotent Windows-host bootstrap for a fresh machine: enables WSL2
  prerequisites, installs a Debian distro, installs Scoop + Chocolatey,
  then installs Windows Terminal and Podman Desktop via Chocolatey.

.DESCRIPTION
  This file is NOT Nix-managed. It lives in windows/ as plain
  preparation material for a brand-new Windows box that does not yet
  have WSL installed at all. Run it, follow any reboot instructions,
  then re-run it until every check prints [OK]. After this script
  completes, open the new Debian WSL distro and run setup-wsl-nix.sh
  from inside it.

  Re-running this script after everything is installed should only
  print [OK] lines and make no changes (idempotent by design).

.NOTES
  Known constraint this script works around deliberately:
    - Mutating actions (enabling Windows features, `wsl --install`,
      Chocolatey package installs) require an elevated (Administrator)
      PowerShell session.
    - Scoop's own installer explicitly advises against installing as
      Administrator (it changes install paths/permissions assumptions).
    - Reading status, by contrast, does NOT require elevation:
      `wsl --list`, `Get-Command choco`, and reading Chocolatey's
      installed-package folders all work fine from a standard, non-
      elevated session. Only `Get-WindowsOptionalFeature`'s elevation
      requirement is unconfirmed either way by Microsoft's docs (their
      own troubleshooting guide happens to run it elevated); this
      script queries it unelevated first and treats a failed query as
      "unknown, resolve via elevation" rather than guessing.

  Because reads don't need admin, this script ALWAYS checks everything
  first in its current (possibly non-elevated) process. It only spawns
  an elevated child process if that check finds actual pending work
  (a feature not yet enabled, Debian not yet installed, Chocolatey or
  one of its packages missing). A re-run where everything is already
  in place never triggers a UAC prompt at all. If you launch this
  script already elevated (e.g. "Run as administrator"), it performs
  any needed admin actions directly in that same session instead of
  spawning a child.

.NOTES
  Unverified-by-official-docs items, called out explicitly rather than
  assumed (see windows/README.md for the research this was based on):
    - The exact Get-WindowsOptionalFeature .State string values are not
      enumerated in Microsoft's reference docs. This script compares
      against the literal 'Enabled' string, which is the documented
      convention in practice, but Microsoft does not guarantee it.
    - There is no documented, universal "pending reboot" registry check.
      Instead of guessing, this script tracks whether IT enabled a
      feature during the current run and treats that as the signal to
      stop and ask for a reboot.
    - Hardware virtualization firmware state (VT-x/AMD-V) can only be
      enabled in BIOS/UEFI, never from Windows software. The check here
      is informational only and never blocks the script.
#>

[CmdletBinding()]
param(
  [switch]$AdminPhaseOnly
)

Set-StrictMode -Version Latest

# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------

function Write-Ok {
  param([string]$Message)
  Write-Host "[OK]      $Message" -ForegroundColor Green
}

function Write-Install {
  param([string]$Message)
  Write-Host "[INSTALL] $Message" -ForegroundColor Yellow
}

function Write-WarnMsg {
  param([string]$Message)
  Write-Host "[WARN]    $Message" -ForegroundColor DarkYellow
}

function Write-Fail {
  param([string]$Message)
  Write-Host "[FAIL]    $Message" -ForegroundColor Red
}

function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FeatureState {
  # Read-only query. Returns 'Enabled', 'Disabled', or 'Unknown' (the
  # query itself failed -- e.g. because this process isn't elevated
  # and that turns out to matter; Microsoft's docs don't confirm
  # either way, see the script header). Never mutates anything.
  param([string]$FeatureName)
  try {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
    if ($feature.State -eq 'Enabled') { return 'Enabled' }
    return 'Disabled'
  }
  catch {
    return 'Unknown'
  }
}

function Show-VirtualizationStatus {
  # Firmware (BIOS/UEFI) virtualization support cannot be queried with
  # full certainty from a single documented PowerShell property, and it
  # can never be toggled from Windows. This check is read-only,
  # informational, and never fails the caller.
  Write-Host ""
  Write-Host "== Hardware virtualization (informational only) =="
  try {
    $computerInfo = Get-ComputerInfo -Property 'HyperVRequirementVirtualizationFirmwareEnabled', 'HyperVisorPresent' -ErrorAction Stop
    if ($computerInfo.HyperVRequirementVirtualizationFirmwareEnabled -eq $true) {
      Write-Ok "Firmware reports virtualization (VT-x/AMD-V) enabled."
    }
    elseif ($computerInfo.HyperVisorPresent -eq $true) {
      Write-Ok "A hypervisor is already present and running."
    }
    else {
      Write-WarnMsg "Could not confirm virtualization is enabled in firmware."
      Write-WarnMsg "If WSL2 fails to start a VM later, enable VT-x/AMD-V in your BIOS/UEFI setup."
    }
  }
  catch {
    Write-WarnMsg "Could not query virtualization firmware state (non-fatal): $($_.Exception.Message)"
  }
}

function Test-ChocoPackageInstalled {
  param([string]$PackageId)
  # Checked by inspecting Chocolatey's own installed-package layout
  # (each installed package gets a folder under lib\<id>). Chocolatey's
  # current `choco list` reference does not document a stable
  # installed-only query, so this filesystem check is used instead of
  # guessing at an undocumented flag. Chocolatey's default install ACL
  # grants the built-in Users group read/execute on this path, so this
  # works fine from a non-elevated session.
  $libPath = Join-Path $env:ProgramData "chocolatey\lib\$PackageId"
  return Test-Path $libPath
}

# WSL optional features and Chocolatey packages this script manages.
# Defined once at script scope so the read-only pre-check
# (Test-AdminWorkPending) and the actual mutating phase
# (Invoke-AdminPhase) can never drift out of sync with each other.
$script:WslFeatures = @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')

$script:ChocoPackages = @(
  @{ Id = 'microsoft-windows-terminal'; Name = 'Windows Terminal' },
  @{ Id = 'podman-desktop'; Name = 'Podman Desktop' }
)

function Test-AdminWorkPending {
  # Read-only pass over every admin-gated check, safe to run from a
  # non-elevated session (see .NOTES above for which reads are
  # confirmed non-admin vs. unconfirmed). Prints the same [OK]/
  # [INSTALL] status a user would see after elevating, and returns
  # $true if anything still needs the admin phase to run.
  $pending = $false

  Write-Host ""
  Write-Host "== WSL prerequisite features =="
  foreach ($featureName in $script:WslFeatures) {
    switch (Get-FeatureState -FeatureName $featureName) {
      'Enabled' { Write-Ok "Windows feature already enabled: $featureName" }
      'Disabled' {
        Write-Install "Windows feature not yet enabled: $featureName"
        $pending = $true
      }
      'Unknown' {
        Write-WarnMsg "Could not determine state of '$featureName' without elevation; will resolve once elevated."
        $pending = $true
      }
    }
  }

  Show-VirtualizationStatus

  Write-Host ""
  Write-Host "== WSL + Debian distro =="
  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-WarnMsg "wsl.exe not found yet (expected until WSL features are enabled and the machine rebooted)."
    $pending = $true
  }
  else {
    Write-Ok "wsl.exe is present."
    # wsl --list --quiet output can contain embedded NUL bytes when
    # captured from PowerShell; strip them before comparing names.
    $rawDistros = & wsl.exe --list --quiet 2>$null
    $distros = $rawDistros | ForEach-Object { $_ -replace "`0", '' } | Where-Object { $_.Trim() -ne '' }
    if ($distros -contains 'Debian') {
      Write-Ok "WSL distro 'Debian' is already registered."
    }
    else {
      Write-Install "WSL distro 'Debian' is not yet registered."
      $pending = $true
    }
  }

  Write-Host ""
  Write-Host "== Chocolatey =="
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Ok "Chocolatey is already installed."
  }
  else {
    Write-Install "Chocolatey is not yet installed."
    $pending = $true
  }

  Write-Host ""
  Write-Host "== Windows Terminal + Podman Desktop (via Chocolatey) =="
  foreach ($pkg in $script:ChocoPackages) {
    if (Test-ChocoPackageInstalled -PackageId $pkg.Id) {
      Write-Ok "$($pkg.Name) ($($pkg.Id)) already installed via Chocolatey."
    }
    else {
      Write-Install "$($pkg.Name) ($($pkg.Id)) is not yet installed."
      $pending = $true
    }
  }

  return $pending
}

# ----------------------------------------------------------------------
# Admin phase: WSL features, Debian distro, Chocolatey + its packages
# ----------------------------------------------------------------------

function Invoke-AdminPhase {
  $result = [PSCustomObject]@{
    RebootRequired = $false
    Failed         = $false
  }

  Write-Host ""
  Write-Host "== WSL prerequisite features =="

  $enabledSomething = $false

  foreach ($featureName in $script:WslFeatures) {
    if ((Get-FeatureState -FeatureName $featureName) -eq 'Enabled') {
      Write-Ok "Windows feature already enabled: $featureName"
    }
    else {
      Write-Install "Enabling Windows feature: $featureName"
      try {
        Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All -NoRestart -ErrorAction Stop | Out-Null
        $enabledSomething = $true
      }
      catch {
        Write-Fail "Failed to enable '$featureName': $($_.Exception.Message)"
        $result.Failed = $true
      }
    }
  }

  if ($enabledSomething) {
    $result.RebootRequired = $true
    Write-Host ""
    Write-WarnMsg "One or more WSL features were just enabled for the first time."
    Write-WarnMsg "A reboot is required before WSL2/Debian can be installed."
    Write-Host ""
    Write-Host "Next step: reboot this machine, then re-run this script." -ForegroundColor Cyan
    return $result
  }

  Show-VirtualizationStatus

  Write-Host ""
  Write-Host "== WSL + Debian distro =="

  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-Fail "wsl.exe was not found even though the required features are enabled."
    Write-Fail "Install the 'Windows Subsystem for Linux' update from Windows Update, then re-run."
    $result.Failed = $true
    return $result
  }
  Write-Ok "wsl.exe is present."

  # wsl --list --quiet output can contain embedded NUL bytes when
  # captured from PowerShell; strip them before comparing names.
  $rawDistros = & wsl.exe --list --quiet 2>$null
  $distros = $rawDistros | ForEach-Object { $_ -replace "`0", '' } | Where-Object { $_.Trim() -ne '' }

  if ($distros -contains 'Debian') {
    Write-Ok "WSL distro 'Debian' is already registered."
  }
  else {
    # --no-launch is required here: by default `wsl --install -d <name>`
    # auto-launches the new distro once the download finishes, showing
    # the first-run UNIX username/password prompts (as expected), but
    # then drops straight into an interactive bash shell inside that
    # distro using THIS SAME console. wsl.exe does not exit/return
    # control to this script until the user manually types `exit` from
    # that shell -- confirmed by observing this exact script hang at
    # that point on a real run. --no-launch registers and provisions
    # the distro without ever handing the console over that way; the
    # user completes the username/password setup themselves afterward,
    # on their own schedule, by opening the distro normally.
    Write-Install "Installing WSL distro 'Debian' (registering only; not launching it)..."
    & wsl.exe --install -d Debian --no-launch
    if ($LASTEXITCODE -ne 0) {
      Write-Fail "wsl --install -d Debian exited with code $LASTEXITCODE"
      $result.Failed = $true
    }
    else {
      Write-Host ""
      Write-WarnMsg "Debian is installed but not yet initialized. Open it once from the"
      Write-WarnMsg "Start menu (or run 'wsl -d Debian') to complete first-run setup --"
      Write-WarnMsg "you'll be prompted to create a UNIX username and password."
    }
  }

  Write-Host ""
  Write-Host "== Chocolatey =="

  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Ok "Chocolatey is already installed."
  }
  else {
    Write-Install "Installing Chocolatey..."
    # On machines where a Group Policy-enforced execution policy exists
    # at a broader scope (e.g. LocalMachine via GPO), this per-process
    # override is harmlessly rejected -- PowerShell still prints a
    # non-terminating warning by default even though it does not stop
    # the script. Silence that specific, expected noise with
    # -ErrorAction SilentlyContinue rather than letting it look like a
    # failure; the Chocolatey install below works fine either way as
    # long as the broader, GPO-enforced policy already permits it.
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    # Run Chocolatey's official installer in its own child scope (the
    # `& { ... }` wrapper), NOT inline in this function's scope.
    # Confirmed by reading install.ps1 directly: it declares its own
    # top-level `$result` variable. Invoke-Expression executes in
    # whatever scope calls it, so without this isolation Chocolatey's
    # $result silently overwrote this function's own $result (the
    # PSCustomObject tracking RebootRequired/Failed) -- observed for
    # real, causing "$result.Failed cannot be found" right after this
    # ran. The child scope contains Chocolatey's variables and lets
    # them go out of scope harmlessly when the scriptblock returns.
    & { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) }

    # Make choco available in this same session without a new shell.
    $chocoBin = Join-Path $env:ProgramData 'chocolatey\bin'
    if ($env:Path -notlike "*$chocoBin*") {
      $env:Path = "$env:Path;$chocoBin"
    }

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
      Write-Fail "Chocolatey install did not make 'choco' available on PATH."
      $result.Failed = $true
      return $result
    }
  }

  Write-Host ""
  Write-Host "== Windows Terminal + Podman Desktop (via Chocolatey) =="

  foreach ($pkg in $script:ChocoPackages) {
    if (Test-ChocoPackageInstalled -PackageId $pkg.Id) {
      Write-Ok "$($pkg.Name) ($($pkg.Id)) already installed via Chocolatey."
    }
    else {
      Write-Install "Installing $($pkg.Name) ($($pkg.Id)) via Chocolatey..."
      & choco install $pkg.Id -y
      # Chocolatey's own docs define valid package exit codes as
      # 0, 1605, 1614, 1641, 3010 -- all success, not just 0. 3010
      # specifically means "success, reboot required". Observed for
      # real: Windows Terminal returned 3010 and was incorrectly
      # flagged [FAIL] before this fix even though it installed fine.
      $chocoSuccessCodes = @(0, 1605, 1614, 1641, 3010)
      if ($LASTEXITCODE -notin $chocoSuccessCodes) {
        Write-Fail "choco install $($pkg.Id) exited with code $LASTEXITCODE"
        $result.Failed = $true
      }
      elseif ($LASTEXITCODE -eq 3010) {
        Write-Ok "$($pkg.Name) installed (exit code 3010: success, reboot required)."
        $result.RebootRequired = $true
      }
    }
  }

  Write-Host ""
  Write-WarnMsg "Podman Desktop manages its own WSL2 'podman machine', separate from"
  Write-WarnMsg "the Debian distro installed above. Launch Podman Desktop once and"
  Write-WarnMsg "follow its onboarding flow to create and start that machine; this"
  Write-WarnMsg "script does not automate that first-run GUI step."

  return $result
}

# ----------------------------------------------------------------------
# User phase: Scoop (deliberately NOT run elevated, see header notes)
# ----------------------------------------------------------------------

function Invoke-UserPhase {
  Write-Host ""
  Write-Host "== Scoop =="

  if (Test-IsAdmin) {
    Write-WarnMsg "Running as Administrator. Scoop's own installer advises against this."
    Write-WarnMsg "If the Scoop install below fails, re-run this script from a normal"
    Write-WarnMsg "(non-elevated) PowerShell window instead."
  }

  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Ok "Scoop is already installed."
    return
  }

  Write-Install "Installing Scoop..."
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Ok "Scoop installed."
  }
  else {
    Write-Fail "Scoop install did not make 'scoop' available on PATH."
  }
}

# ----------------------------------------------------------------------
# Entry point
# ----------------------------------------------------------------------
#
# This is the elevated child process spawned below, doing only the
# mutating work. Never invoked directly by a user.
#
# It runs in its own console window (a side effect of -Verb RunAs
# elevation) that closes the instant the script exits, so Write-Host
# output would otherwise be unreviewable if something failed. Start-
# Process's -RedirectStandardOutput/-RedirectStandardError cannot be
# combined with -Verb RunAs (they are mutually exclusive parameter
# sets -- RunAs requires ShellExecute, which cannot redirect standard
# streams). Start-Transcript has no such restriction and does capture
# Write-Host (it records everything that appears on the console), so
# it is used here instead.
if ($AdminPhaseOnly) {
  $logPath = Join-Path $env:TEMP 'bootstrap-windows-admin-phase.log'
  try {
    Start-Transcript -Path $logPath -Append -ErrorAction Stop | Out-Null
  }
  catch {
    Write-WarnMsg "Could not start transcript logging to '$logPath': $($_.Exception.Message)"
  }

  $adminResult = Invoke-AdminPhase

  Write-Host ""
  Write-Host "Full admin-phase log: $logPath"
  try { Stop-Transcript -ErrorAction Stop | Out-Null } catch { }

  # Failed must be checked BEFORE RebootRequired. Since a Chocolatey
  # package can return exit code 3010 ("success, reboot required") for
  # an earlier package while a LATER package in the same loop genuinely
  # fails, both flags can end up true together. Exiting 2 first would
  # silently swallow a real failure behind a "just reboot" message.
  if ($adminResult.Failed) { exit 1 }
  if ($adminResult.RebootRequired) { exit 2 }
  exit 0
}

function Complete-Run {
  Invoke-UserPhase
  Write-Host ""
  Write-Host "Bootstrap complete. Re-run this script any time; it only prints [OK] once everything is in place." -ForegroundColor Cyan
}

# Read-only pass, safe from a non-elevated session. This is what makes
# a fully-satisfied re-run skip elevation (and any UAC prompt) entirely.
Write-Host "== Checking current status (no changes made yet, no elevation needed) =="
$adminWorkPending = Test-AdminWorkPending

if (-not $adminWorkPending) {
  Write-Host ""
  Write-Ok "Nothing admin-level is pending; no elevation needed."
  Complete-Run
  exit 0
}

# Same path the admin phase writes its transcript to (see the
# $AdminPhaseOnly branch above); surfaced here too so a failure or
# reboot message always tells the user where to find the full log,
# regardless of which branch below produced it.
$adminPhaseLogPath = Join-Path $env:TEMP 'bootstrap-windows-admin-phase.log'

if (Test-IsAdmin) {
  # Already elevated (e.g. launched via "Run as administrator"): no
  # need to spawn a child, just do the mutating work directly.
  Write-Host ""
  Write-WarnMsg "Pending admin-level work found, and this session is already elevated; proceeding directly."
  $adminResult = Invoke-AdminPhase
  # Failed checked before RebootRequired -- see comment at the
  # $AdminPhaseOnly branch above for why a reboot-required package can
  # coexist with a genuine failure from a different package.
  if ($adminResult.Failed) {
    Write-Fail "Admin phase reported failures; skipping Scoop phase."
    exit 1
  }
  if ($adminResult.RebootRequired) { exit 2 }
  Complete-Run
  exit 0
}

Write-Host ""
Write-Host "Pending admin-level work found. Requesting elevation (UAC prompt)..." -ForegroundColor Cyan
Write-Host "Any administrator account's credentials can be used here -- you do not need to be logged in as an admin yourself."
Write-Host "The elevated window's output is also logged to: $adminPhaseLogPath"

try {
  $proc = Start-Process -FilePath 'powershell.exe' `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-AdminPhaseOnly') `
    -Verb RunAs -Wait -PassThru -ErrorAction Stop
}
catch {
  Write-Fail "Elevation request failed or was cancelled: $($_.Exception.Message)"
  Write-Fail "Admin-level steps were skipped. Re-run this script and accept the UAC prompt to continue."
  exit 1
}

switch ($proc.ExitCode) {
  2 {
    Write-Host ""
    Write-Host "Reboot required. Reboot this machine, then re-run this script." -ForegroundColor Cyan
    exit 2
  }
  0 {
    Complete-Run
    exit 0
  }
  default {
    Write-Fail "Admin phase failed (exit code $($proc.ExitCode))."
    Write-Fail "The elevated window has already closed. Full output was logged to: $adminPhaseLogPath"
    exit 1
  }
}
