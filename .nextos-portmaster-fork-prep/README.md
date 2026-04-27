# PortMaster NextOS support — upstream PR prep

This dir tracks the "NextOS-Elite-Edition aliasing" patch that was
applied locally via packages/addons/portmaster/scripts/start_portmaster.sh
(idempotent first-run patch on extracted PortMaster.zip).

## Files

- `0001-Recognize-NextOS-Elite-Edition-as-EmuELEC-fork.patch` — diff
  ready to submit upstream. The hunk markers (X,Y) need adjustment to
  match the current upstream line numbers when opening the PR.

## How to submit upstream

1. Fork https://github.com/PortsMaster/PortMaster-GUI
2. Cherry-pick the 2 hunks above (or replicate manually):
   - `PortMaster/pylibs/harbourmaster/hardware.py` — add NextOS alias
     before `info.setdefault('name', 'Unknown')`
   - `PortMaster/pylibs/harbourmaster/platform.py` — add `'nextos':
     PlatformEmuELEC` line right after `'emuelec'`
3. Test locally that EmuELEC + NextOS both still work
4. Open PR with the body of the .patch file as description

## Approach B (full fork) — defer

Forking PortMaster-GUI under felc18-blip and repointing the PKG_URL is
**not needed** because the in-tree start_portmaster.sh patch handles
it idempotently. Only fork if upstream rejects the PR or NextOS needs
divergent changes that don't fit upstream.
