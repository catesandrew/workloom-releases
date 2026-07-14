# workloom-releases

Public release binaries + installer for the Workloom CLI (`wl`) and desktop
app. Source lives in the private `catesandrew/workloom-baro-x` repo — this
repo exists only so the install script and prebuilt binaries are reachable
without a private-repo token.

Nothing here is hand-edited: `scripts/install.sh` and `docs/unsigned-builds.md`
are synced, and release assets are published, by
`.github/workflows/release.yml` in the source repo on every `v*` tag.

Install:

```bash
curl -fsSL https://raw.githubusercontent.com/catesandrew/workloom-releases/main/scripts/install.sh | bash
```
