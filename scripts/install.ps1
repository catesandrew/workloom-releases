#!/usr/bin/env pwsh
#
# Workloom CLI installer (Windows).
#
#   irm https://raw.githubusercontent.com/catesandrew/workloom-releases/main/scripts/install.ps1 | iex
#
# Downloads the prebuilt `wl.exe` binary for Windows (x64) from GitHub Releases,
# verifies its SHA-256 checksum, and installs it to
# $env:LOCALAPPDATA\Workloom\bin (override with WL_INSTALL_DIR). Set WL_VERSION
# to pin a release tag (default: latest).
#
# Source lives in the private catesandrew/workloom repo; this file and the
# release assets it downloads are mirrored to the public
# catesandrew/workloom-releases repo by .github/workflows/release-desktop.yml so
# anonymous `irm | iex` works without a private-repo token.
#
# This is the Windows sibling of scripts/install.sh. Only windows-x64 binaries
# are compiled (see apps/cli/scripts/build-binary.mjs), and — unlike the desktop
# app — the CLI ships the raw `wl-windows-x64.exe`, not a zip.

$ErrorActionPreference = 'Stop'

$Repo = if ($env:WORKLOOM_REPO) { $env:WORKLOOM_REPO } else { 'catesandrew/workloom-releases' }
$BinName = 'wl'
$InstallDir = if ($env:WL_INSTALL_DIR) { $env:WL_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Workloom\bin' }
$Version = if ($env:WL_VERSION) { $env:WL_VERSION } else { 'latest' }

# Windows binaries are only built for x64.
$Asset = "$BinName-windows-x64.exe"

# --- Resolve base URL --------------------------------------------------------
if ($Version -eq 'latest') {
  $Base = "https://github.com/$Repo/releases/latest/download"
} else {
  $Base = "https://github.com/$Repo/releases/download/$Version"
}

Write-Host "Installing $BinName (windows-x64, $Version) from $Repo"

$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("wl-" + [System.Guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
try {
  # --- Download binary + checksums -------------------------------------------
  $bin = Join-Path $Tmp $Asset
  try { Invoke-WebRequest -UseBasicParsing -Uri "$Base/$Asset" -OutFile $bin }
  catch { throw "download failed: $Base/$Asset (no build for windows-x64?)" }

  # --- Verify checksum (mandatory: every release ships SHA256SUMS) -----------
  $sums = Join-Path $Tmp 'SHA256SUMS'
  try { Invoke-WebRequest -UseBasicParsing -Uri "$Base/SHA256SUMS" -OutFile $sums }
  catch { throw "could not fetch SHA256SUMS for $Version - refusing to install unverified binary" }
  $expected = (Select-String -Path $sums -Pattern " $([regex]::Escape($Asset))$" | Select-Object -First 1).Line -split '\s+' | Select-Object -First 1
  if (-not $expected) { throw "no checksum for $Asset in SHA256SUMS" }
  $actual = (Get-FileHash -Algorithm SHA256 -Path $bin).Hash.ToLower()
  if ($expected.ToLower() -ne $actual) { throw "checksum mismatch for $Asset (expected $expected, got $actual)" }
  Write-Host 'Checksum verified.'

  # --- Install ---------------------------------------------------------------
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  $dest = Join-Path $InstallDir "$BinName.exe"
  Move-Item -Force -Path $bin -Destination $dest
  Write-Host "Installed $BinName -> $dest"

  # --- PATH hint -------------------------------------------------------------
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$InstallDir", 'User')
    Write-Host "Added $InstallDir to your user PATH. Restart your shell, then run: $BinName --help"
  } else {
    Write-Host "Run: $BinName --help"
  }
}
finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
