# Running unsigned builds

Pre-launch Workloom builds — the `wl` CLI binary and the desktop app — are **not
yet code-signed or notarized**. This is a deliberate pre-launch choice, not a
defect: signing costs recurring money + CI setup that isn't justified before
launch. This page explains what you'll see and how to run the builds safely.

## Are they safe?

Yes. The trust comes from provenance, not a signature:

- The `curl | bash` installer downloads from GitHub Releases and **verifies a
  SHA-256 checksum** (`SHA256SUMS`) before installing — a tampered binary fails.
- Every artifact is built in **public GitHub Actions** from a tagged commit; the
  build is auditable.
- You can inspect the installer before running it (see the README Install
  section).

The OS warnings below are about *"we can't verify the publisher"* (no paid
signing cert), not *"this is malware."*

## macOS

### CLI via `curl | bash` — no warning

The installer writes the binary without the `com.apple.quarantine` flag, so it
runs immediately. Nothing to do.

### CLI binary downloaded manually from Releases

A browser download gets quarantined. Clear the flag once:

```bash
xattr -d com.apple.quarantine ./wl
./wl --help
```

### Desktop `.app` / `.dmg`

Gatekeeper blocks the first launch. Either:

- **Right-click the app → Open → Open** (the right-click bypasses the block; you
  only confirm once), or
- clear the flag from a terminal:

  ```bash
  xattr -dr com.apple.quarantine "/Applications/Workloom.app"
  ```

If macOS says the app "is damaged and can't be opened," that's still the
quarantine flag on an unsigned bundle — the `xattr -dr` command above fixes it.

## Windows

SmartScreen shows **"Windows protected your PC"** on first run of an unsigned
`.exe` or `.msi`. To run it:

1. Click **More info**.
2. Click **Run anyway**.

Optionally unblock the file first so the prompt doesn't recur:

- Right-click the downloaded file → **Properties** → check **Unblock** → **OK**.

## Linux

No OS signing gate. If the binary isn't executable:

```bash
chmod +x wl
./wl --help
```

## When will builds be signed?

Signing is a post-launch follow-up:

- **macOS** — Apple Developer ID cert ($99/yr) + notarization; removes the
  Gatekeeper prompt entirely.
- **Windows** — Azure Trusted Signing (~$10/mo) or an OV/EV cert; removes the
  SmartScreen "unknown publisher" block (EV also earns instant reputation).

Until then, the steps above are the supported path.
