# Phase 1: Package & Install - Research

**Researched:** 2026-04-16
**Domain:** GodotModLoader local mod installation, manifest schema, ZIP packaging
**Confidence:** HIGH — all key findings verified directly against live game logs and loader source

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Copy raw mod folders (`kuuk-SmartThreadManager/` and `kuuk-SmartGPUManager/`) directly into `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods-unpacked/`. No zip packaging. No symlinks.
- **D-02:** Add `"2.1.10"` to `compatible_game_version` in both manifests.
- **D-03:** Check what version of GodotModLoader the 2.1.10 game ships; add it to `compatible_mod_loader_version` if it is newer than `7.0.1`.
- **D-04:** Set `version_number` to `"2.1.10"` in both manifests.
- **D-05:** Trim `compatible_game_version` to only versions that have been tested. Remove untested legacy entries (`2.0.0`, `2.0.17`, `2.0.19`, `2.0.20`, `2.0.21`) — keep `2.1.8` (last known working) and add `2.1.10`.
- **D-06:** Phase 1 is not complete until all four success criteria pass: (1) game launches, (2) GodotModLoader log shows no init errors for either mod, (3) both mod windows appear in-game, (4) both windows accept connections.

### Claude's Discretion
- How to detect the GodotModLoader version bundled with the game (inspect EXE, check mod loader files, or read a version file in the game dir)
- Exact trimmed `compatible_game_version` list format (ordering, whitespace)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INST-01 | Package SmartThreadManager source into a loadable mod zip/folder | Research resolves packaging format: ZIP with `mods-unpacked/` internal root, placed in `game_dir/mods/` |
| INST-02 | Package SmartGPUManager source into a loadable mod zip/folder | Same as INST-01 — identical packaging steps |
| INST-03 | Install both mods into the game's local mods directory so they load without Steam Workshop | Verified install path is `game_dir/mods/` (see Critical Finding below) |
| COMP-01 | Update both manifests to include `"2.1.10"` in `compatible_game_version` | Manifest schema verified; JSON array string append |
| COMP-02 | Both mods must initialize without errors in the mod loader log | Log format and error patterns documented; verification command identified |
| CODE-02 | `smart_resource_container.gd` uses `extends ResourceContainer` | Verified at source level — first line confirmed correct in both mods |
</phase_requirements>

---

## Summary

GodotModLoader in Upload Labs 2.1.10 scans three locations for mods, in order: the embedded PCK virtual path `res://mods-unpacked/` (fails on this game — no mods baked in), then `game_dir/mods/` on disk (for ZIP/PCK files), then Steam Workshop directories. The key finding is that the loader does **not** scan `game_dir/mods-unpacked/` for loose unpacked folders in a released game. Local installation therefore requires ZIP files placed in a `mods/` directory alongside the EXE, not loose folder copies into `mods-unpacked/`.

Decision D-01 (copy raw mod folders to `mods-unpacked/`) conflicts with the observed loader behavior. Research recommends revising D-01 to use ZIP packaging in `game_dir/mods/` instead. The ZIP internal structure must begin with `mods-unpacked/` so the virtual filesystem maps correctly after extraction.

Both manifests currently list `version_number: "2.1.5"` and `compatible_game_version` containing versions up to `2.1.8`. Both need updating per D-02 through D-05. The GodotModLoader version check is not enforced (mods loaded fine with mismatched version in active logs), but updating the manifest is still correct and required by the phase decisions. GodotModLoader 7.0.1 is the latest release — D-03 requires no changes since 7.0.1 is already in both manifests. CODE-02 is already satisfied at the source level.

**Primary recommendation:** Package each mod as a ZIP containing `mods-unpacked/kuuk-{Name}/...`, create `game_dir/mods/`, place ZIPs there. Update manifests before zipping. This is the install method the loader is observed to use.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mod discovery | Game runtime (GodotModLoader) | — | Loader owns scan path logic — we configure, not control |
| Manifest validation | Game runtime (GodotModLoader) | — | Loader reads and validates manifest on load |
| ZIP packaging | Developer (build step) | — | Must match loader's expected ZIP structure |
| File copy to install dir | Developer (copy step) | — | Filesystem operation outside game |
| Version string edit | Developer (manifest edit) | — | JSON text edit before packaging |
| Log verification | Developer (manual check) | — | Read `%APPDATA%\Upload Labs\logs\modloader.log` post-launch |

---

## CRITICAL FINDING: Install Path Conflict with D-01

**D-01 says:** Copy raw mod folders directly into `game_dir/mods-unpacked/`.

**What the loader actually does** (verified from `%APPDATA%\Upload Labs\logs\modloader.log` on four separate sessions):

```
ERROR  ModLoader:Path: Encountered an error when attempting to open a directory: res://mods-unpacked/
INFO   ModLoader:Path: The directory for mods at path "D:/.../Upload Labs/mods" does not exist.
INFO   ModLoader:ThirdParty:Steam: Checking workshop items, with path: "D:/.../workshop/content/3606890"
```

The loader checks `mods` (ZIP scan path) — not `mods-unpacked/` — on disk. The `mods-unpacked/` directory **exists and is empty** in the game folder but is never mentioned in the scan sequence. Placing loose folders there will not cause them to be loaded.

**Corrected approach:** Create `game_dir/mods/` directory and put ZIP files there.

[VERIFIED: modloader.log — four separate game sessions, 2026-04-14 through 2026-04-15]

---

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| PowerShell `Compress-Archive` | Built into Windows 11 | Create mod ZIPs | Available on target machine; no install required |
| GodotModLoader | 7.0.1 (latest) | Mod discovery and loading | Bundled in game; not a separate install |

### Environment
| Item | Path | Status |
|------|------|--------|
| Game EXE | `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/Upload Labs.exe` | Confirmed present, last modified 2026-04-12 |
| Game mods dir (to create) | `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/` | Does not yet exist — must be created |
| Game mods-unpacked dir | `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods-unpacked/` | Exists, empty — NOT scanned by loader |
| Mod loader log | `%APPDATA%\Upload Labs\logs\modloader.log` | Confirmed location, readable |
| STM source | `C:/Users/Jake/Projects/Upload Smrt Nodes/Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/` | 17 files confirmed |
| SGM source | `C:/Users/Jake/Projects/Upload Smrt Nodes/Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/` | 17 files confirmed |

---

## Architecture Patterns

### ZIP Internal Structure (Required)

The loader extracts ZIPs into the virtual filesystem rooted at `res://`. Each ZIP must contain the `mods-unpacked/` folder so the result maps to `res://mods-unpacked/namespace-name/`. Verified against the working `Bottlenecks.zip` from Steam Workshop:

```
kuuk-SmartThreadManager.zip
└── mods-unpacked/
    └── kuuk-SmartThreadManager/
        ├── manifest.json
        ├── mod_main.gd
        ├── scenes/
        ├── scripts/
        ├── textures/
        └── translations/
```

[VERIFIED: unzip -l Bottlenecks.zip from workshop dir 3651033564]

### Packaging Command

Run from the mod's parent directory (e.g., `Smrt Thread Manager/`) so the `mods-unpacked/` folder is at the ZIP root:

```powershell
# From: C:\Users\Jake\Projects\Upload Smrt Nodes\Smrt Thread Manager\
Compress-Archive -Path mods-unpacked -DestinationPath kuuk-SmartThreadManager.zip -Force
```

```powershell
# From: C:\Users\Jake\Projects\Upload Smrt Nodes\Smrt GPU Manager\
Compress-Archive -Path mods-unpacked -DestinationPath kuuk-SmartGPUManager.zip -Force
```

### Manifest JSON Schema (both mods use identical schema)

Current state of both `manifest.json` files:
```json
{
    "namespace": "kuuk",
    "name": "SmartThreadManager",
    "version_number": "2.1.5",
    "dependencies": [],
    "extra": {
        "godot": {
            "compatible_game_version": ["2.0.0", "2.0.17", "2.0.19", "2.0.20", "2.0.21", "2.1.8"],
            "compatible_mod_loader_version": ["7.0.0", "7.0.1"]
        }
    }
}
```

Required state after Phase 1 edits:
```json
{
    "namespace": "kuuk",
    "name": "SmartThreadManager",
    "version_number": "2.1.10",
    "dependencies": [],
    "extra": {
        "godot": {
            "compatible_game_version": ["2.1.8", "2.1.10"],
            "compatible_mod_loader_version": ["7.0.0", "7.0.1"]
        }
    }
}
```

Changes applied (per decisions D-02 through D-05):
- `version_number`: `"2.1.5"` → `"2.1.10"`
- `compatible_game_version`: trim to `["2.1.8", "2.1.10"]` (remove 5 legacy entries, add 2.1.10)
- `compatible_mod_loader_version`: **no change** — 7.0.1 is already present and is the latest release

[VERIFIED: manifest.json files read directly; GodotModLoader releases page confirmed 7.0.1 is latest]

---

## D-03 Resolution: GodotModLoader Version

**Decision D-03 asks:** Check what version of GodotModLoader the 2.1.10 game ships; add it to `compatible_mod_loader_version` if it is newer than 7.0.1.

**Finding:** GodotModLoader 7.0.1 is the latest release as of April 2026. The game's bundled loader does not print its version in the mod loader log. However, since 7.0.1 is the latest available, the game cannot be running anything newer. Both manifests already include 7.0.1.

**Action required from D-03:** None. No change to `compatible_mod_loader_version`.

[VERIFIED: GodotModLoader releases page — https://github.com/GodotModding/godot-mod-loader/releases]

---

## CODE-02 Verification

`smart_resource_container.gd` first line in both mods:
```gdscript
extends ResourceContainer
```

Confirmed present in both source trees before any Phase 1 edits. CODE-02 is satisfied at the source level.

[VERIFIED: Read tool on both source files directly]

---

## Common Pitfalls

### Pitfall 1: Wrong Install Directory
**What goes wrong:** Copying mod folders to `game_dir/mods-unpacked/` instead of packaging as ZIPs in `game_dir/mods/`. Mods silently not found — loader never logs scanning `mods-unpacked/` as a loose-folder path.
**Why it happens:** The `mods-unpacked/` directory exists in the game folder and is the virtual FS path for loaded mods, creating an expectation it is also a scan source.
**How to avoid:** Use `game_dir/mods/` with ZIP files. Create the `mods/` directory if it doesn't exist.
**Warning signs:** Loader log shows no mods found; no `kuuk-SmartThreadManager` lines in modloader.log.

### Pitfall 2: Wrong ZIP Root Structure
**What goes wrong:** Zipping the `kuuk-SmartThreadManager/` folder directly, producing a ZIP that contains `kuuk-SmartThreadManager/` at root instead of `mods-unpacked/kuuk-SmartThreadManager/`.
**Why it happens:** Running `Compress-Archive -Path kuuk-SmartThreadManager` from inside the `mods-unpacked/` dir, or zipping from the wrong working directory.
**How to avoid:** Always run `Compress-Archive -Path mods-unpacked` from the mod's parent directory (`Smrt Thread Manager/` or `Smrt GPU Manager/`). Verify ZIP contents with `Expand-Archive` or `unzip -l` before copying to `game_dir/mods/`.
**Warning signs:** Loader finds the ZIP but fails to load mod, or loads with wrong `res://` path.

### Pitfall 3: Stale mod_user_profiles.json Entries
**What goes wrong:** Fear that the stale `zip_path` entries in `%APPDATA%\Upload Labs\mod_user_profiles.json` (pointing to deleted Workshop dirs for both kuuk mods) will block loading.
**Why it happens:** The file has `zip_path` entries for `3631577623` and `3634301126` Workshop dirs that no longer exist on disk.
**How to avoid:** Do nothing. The loader gracefully handles missing zip_path entries and auto-updates profiles on each scan. Observed in logs: the loader ran cleanly even with stale profile entries.
**Warning signs:** None expected — the loader overwrites profile entries on each scan.

### Pitfall 4: Zipping After Manifest Edit (order of operations)
**What goes wrong:** Creating ZIPs before editing manifests, then forgetting to re-zip after the edit.
**How to avoid:** Edit both `manifest.json` files first, then create ZIPs. In the plan, manifest edit tasks must come before ZIP packaging tasks.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ZIP creation | Custom packaging script | `Compress-Archive` (PowerShell built-in) | Already available, handles binary files correctly |
| Log parsing | Manual grep | Read `modloader.log` directly | The log is human-readable and grep-friendly |
| Manifest validation | JSON schema validator | Read log output | Loader itself reports manifest errors on startup |

---

## Verification Protocol (post-install)

1. Launch `Upload Labs.exe`
2. Read `%APPDATA%\Upload Labs\logs\modloader.log` (created fresh each launch)
3. Check for these SUCCESS lines:
   ```
   SUCCESS kuuk:STM:Main: Initialized, version: 2.1.10
   SUCCESS kuuk:SGM:Main: Initialized, version: 2.1.10
   ```
4. Check that NO ERROR lines mention `kuuk-SmartThreadManager` or `kuuk-SmartGPUManager`
5. In-game: place a SmartThreadManager window and a SmartGPUManager window — both must render
6. Connect both windows to downstream windows — connections must be accepted

**Log location:** `C:\Users\Jake\AppData\Roaming\Upload Labs\logs\modloader.log`

---

## Runtime State Inventory

> This phase does NOT rename or refactor existing identifiers — this section uses the standard install/update framing.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `mod_user_profiles.json` has stale `zip_path` entries for both kuuk mods pointing to deleted Workshop dirs (3631577623, 3634301126) | No action — loader auto-overwrites profile entries on each scan |
| Live service config | None — game reads from `game_dir/mods/` on startup; no external service config | None |
| OS-registered state | None — no Task Scheduler tasks, no Windows services for this game | None |
| Secrets/env vars | None | None |
| Build artifacts | None — source is plain GDScript + resources, no compiled artifacts | None |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PowerShell `Compress-Archive` | ZIP packaging | Yes | Windows 11 built-in | 7-Zip CLI if needed |
| Upload Labs.exe | Launch verification | Yes | Build 22035660 (2026-04-12) | — |
| `%APPDATA%\Upload Labs\logs\` | Verification | Yes | Confirmed present | — |

**Missing dependencies with no fallback:** None.

---

## Open Questions

1. **D-01 Conflict: mods-unpacked vs mods/**
   - What we know: Loader scans `game_dir/mods/` for ZIPs; does not log scanning `game_dir/mods-unpacked/` for loose folders
   - What's unclear: Whether D-01 was based on a different version of GodotModLoader that did scan `mods-unpacked/` on disk
   - Recommendation: **Override D-01** — use ZIP packaging in `game_dir/mods/`. This is the only install method confirmed by log evidence. The planner should note this decision override with rationale.

2. **Game version confirmation**
   - What we know: Steam buildid 22035660, last updated 2026-04-12; CONTEXT.md states 2.1.10
   - What's unclear: The game never logs its own version number
   - Recommendation: Accept 2.1.10 per CONTEXT.md. If concerned, the version string "2.1.10" appears in no log — it's simply the label used by the CONTEXT.md author.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GodotModLoader 7.0.1 is the latest version and the game does not bundle anything newer | D-03 Resolution | If game bundles a newer unreleased version, `compatible_mod_loader_version` would need updating — but loader doesn't enforce this check anyway |
| A2 | `game_dir/mods/` is the correct local install path for this specific game's bundled loader version | Critical Finding | If this game's bundled loader has a custom path override, ZIPs in `mods/` would not be found — but log confirms loader checks this path |

---

## Sources

### Primary (HIGH confidence)
- `%APPDATA%\Upload Labs\logs\modloader.log` — four sessions of loader scan path behavior, mod loading sequence
- `%APPDATA%\Upload Labs\logs\godot2026-04-15T08.08.33.log` — full session with 6 mods loading from Workshop
- `Bottlenecks.zip` from Steam Workshop (3651033564) — confirmed ZIP internal structure via `unzip -l`
- Both `manifest.json` source files — current field values verified by direct read
- Both `smart_resource_container.gd` first lines — CODE-02 verified by direct read
- GodotModLoader `mod_loader_store.gd` — `UNPACKED_DIR = "res://mods-unpacked/"` constant
- GodotModLoader `path.gd` — `get_local_folder_dir()` returns `game_dir/mods` as scan path

### Secondary (MEDIUM confidence)
- GodotModLoader releases page (https://github.com/GodotModding/godot-mod-loader/releases) — 7.0.1 confirmed latest

### Tertiary (LOW confidence — not needed for this phase)
- None

---

## Metadata

**Confidence breakdown:**
- Install path: HIGH — four log sessions confirm `mods/` is the scan path
- ZIP structure: HIGH — verified against working Bottlenecks.zip
- Manifest schema: HIGH — read directly from source files
- GodotModLoader version: HIGH — confirmed 7.0.1 is latest via releases page
- CODE-02 status: HIGH — read first line of both source files

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 (stable game; no known updates pending)
