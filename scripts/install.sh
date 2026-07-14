#!/usr/bin/env bash
#
# Workloom CLI installer.
#
#   curl -fsSL https://raw.githubusercontent.com/catesandrew/workloom-releases/main/scripts/install.sh | bash
#
# Downloads the prebuilt `wl` binary for your platform from GitHub Releases,
# verifies its SHA-256 checksum, and installs it to ~/.local/bin (override with
# WL_INSTALL_DIR). Set WL_VERSION to pin a release tag (default: latest).
#
# Source lives in the private catesandrew/workloom-baro-x repo; this file and
# the release assets it downloads are mirrored to the public
# catesandrew/workloom-releases repo by .github/workflows/release.yml so
# anonymous `curl | bash` works without a private-repo token.
#
set -euo pipefail

REPO="catesandrew/workloom-releases"
BIN_NAME="wl"
INSTALL_DIR="${WL_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${WL_VERSION:-latest}"

err() { printf 'error: %s\n' "$1" >&2; exit 1; }
info() { printf '%s\n' "$1" >&2; }

need() { command -v "$1" >/dev/null 2>&1 || err "required command not found: $1"; }
need uname
need mkdir
need chmod

# A downloader: prefer curl, fall back to wget.
if command -v curl >/dev/null 2>&1; then
  dl() { curl -fsSL "$1" -o "$2"; }
  dl_stdout() { curl -fsSL "$1"; }
elif command -v wget >/dev/null 2>&1; then
  dl() { wget -qO "$2" "$1"; }
  dl_stdout() { wget -qO- "$1"; }
else
  err "need curl or wget to download"
fi

# --- Detect platform ---------------------------------------------------------
raw_os="$(uname -s)"
case "$raw_os" in
  Darwin) os="macos" ;;
  Linux)  os="linux" ;;
  MINGW* | MSYS* | CYGWIN*) err "Windows: download wl-windows-x64.exe from the Releases page instead" ;;
  *) err "unsupported OS: $raw_os" ;;
esac

raw_arch="$(uname -m)"
case "$raw_arch" in
  x86_64 | amd64) arch="x64" ;;
  arm64 | aarch64) arch="arm64" ;;
  *) err "unsupported architecture: $raw_arch" ;;
esac

asset="${BIN_NAME}-${os}-${arch}"

# --- Resolve version + base URL ---------------------------------------------
if [ "$VERSION" = "latest" ]; then
  base="https://github.com/${REPO}/releases/latest/download"
else
  base="https://github.com/${REPO}/releases/download/${VERSION}"
fi

info "Installing ${BIN_NAME} (${os}-${arch}, ${VERSION}) from ${REPO}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- Download binary + checksums --------------------------------------------
dl "${base}/${asset}" "${tmp}/${asset}" \
  || err "download failed: ${base}/${asset} (no build for ${os}-${arch}?)"

# --- Verify checksum (mandatory: every release ships SHA256SUMS) ------------
dl "${base}/SHA256SUMS" "${tmp}/SHA256SUMS" \
  || err "could not fetch SHA256SUMS for ${VERSION} — refusing to install unverified binary"
expected="$(grep " ${asset}\$" "${tmp}/SHA256SUMS" | awk '{print $1}')"
[ -n "$expected" ] || err "no checksum for ${asset} in SHA256SUMS"
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "${tmp}/${asset}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "${tmp}/${asset}" | awk '{print $1}')"
else
  err "need sha256sum or shasum to verify checksum"
fi
[ "$expected" = "$actual" ] || err "checksum mismatch for ${asset} (expected ${expected}, got ${actual})"
info "Checksum verified."

# --- Install -----------------------------------------------------------------
mkdir -p "$INSTALL_DIR"
chmod +x "${tmp}/${asset}"
mv "${tmp}/${asset}" "${INSTALL_DIR}/${BIN_NAME}"

info "Installed ${BIN_NAME} -> ${INSTALL_DIR}/${BIN_NAME}"

# --- PATH hint ---------------------------------------------------------------
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) info "Run: ${BIN_NAME} --help" ;;
  *)
    info ""
    info "${INSTALL_DIR} is not on your PATH. Add it:"
    info "  export PATH=\"${INSTALL_DIR}:\$PATH\""
    info "Then run: ${BIN_NAME} --help"
    ;;
esac
