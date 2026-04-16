# Phase 1: Package & Install - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Install both mod folders into the game's local `mods-unpacked/` directory and update both manifests so GodotModLoader recognizes them in Upload Labs 2.1.10. Phase 1 is complete when the game launches, the loader log is clean for both mods, both mod windows appear, and both accept connections.

</domain>

<decisions>
## Implementation Decisions

### Install Method
- **D-01:** Copy raw mod folders (`kuuk-SmartThreadManager/` and `kuuk-SmartGPUManager/`) directly into `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods-unpacked/`. No zip packaging. No symlinks.

### Manifest Changes
- **D-02:** Add `"2.1.10"` to `compatible_game_version` in both manifests.
- **D-03:** Check what version of GodotModLoader the 2.1.10 game ships; add it to `compatible_mod_loader_version` if it is newer than `7.0.1`.
- **D-04:** Set `version_number` to `"2.1.10"` in both manifests.
- **D-05:** Trim `compatible_game_version` to only versions that have been tested. Remove untested legacy entries (`2.0.0`, `2.0.17`, `2.0.19`, `2.0.20`, `2.0.21`) — keep `2.1.8` (last known working) and add `2.1.10`.

### Phase 1 Done Condition
- **D-06:** Phase 1 is not complete until all four success criteria pass: (1) game launches, (2) GodotModLoader log shows no init errors for either mod, (3) both mod windows appear in-game, (4) both windows accept connections.

### Claude's Discretion
- How to detect the GodotModLoader version bundled with the game (inspect EXE, check mod loader files, or read a version file in the game dir)
- Exact trimmed `compatible_game_version` list format (ordering, whitespace)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above.

### Source Files
- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/manifest.json` — STM manifest to update
- `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/manifest.json` — GPU manifest to update

### Game Install
- `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods-unpacked/` — target install directory (currently empty)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Both mod source trees are already structured as `kuuk-{ModName}/` — correct GodotModLoader unpacked format, no restructuring needed.
- `manifest.json` in both mods follows the same schema — both need identical changes.

### Established Patterns
- GodotModLoader loads from `mods-unpacked/{namespace}-{name}/` subfolders directly — no zip required for local install.
- `compatible_game_version` is an array of strings; add entries to extend support.

### Integration Points
- Copy destination: `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods-unpacked/`
- Verification: game launch → check loader log (typically at `%APPDATA%/Upload Labs/logs/` or similar) for init errors

</code_context>

<specifics>
## Specific Ideas

- `version_number` should be `"2.1.10"` in both manifests (not `"2.1.5-fix"` or any other variant)
- Trim `compatible_game_version` to `["2.1.8", "2.1.10"]` — remove untested legacy versions

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-package-install*
*Context gathered: 2026-04-16*
