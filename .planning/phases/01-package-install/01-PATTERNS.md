# Phase 1: Package & Install - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 2 (manifest.json edits only — no new code files in this phase)
**Analogs found:** 2 / 2 (both manifests are analogs of each other — identical schema)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/manifest.json` | config | transform | `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/manifest.json` | exact — identical schema |
| `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/manifest.json` | config | transform | `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/manifest.json` | exact — identical schema |

**No new source code files are created in this phase.** Phase 1 work is: (1) edit both manifests, (2) create two ZIPs, (3) create game mods directory, (4) copy ZIPs, (5) verify via log.

---

## Pattern Assignments

### `kuuk-SmartThreadManager/manifest.json` (config, transform)

**Analog:** `kuuk-SmartGPUManager/manifest.json` — identical schema, identical changes required.

**Current state** (lines 1-39 of `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/manifest.json`):
```json
{
	"dependencies": [],
	"description": "Smart distributor for CPU speed.",
	"extra": {
		"godot": {
			"authors": ["kuuk"],
			"compatible_game_version": [
				"2.0.0",
				"2.0.17",
				"2.0.19",
				"2.0.20",
				"2.0.21",
				"2.1.8"
			],
			"compatible_mod_loader_version": ["7.0.0", "7.0.1"],
			"config_schema": {},
			"description_rich": "",
			"image": null,
			"incompatibilities": [],
			"load_before": [],
			"optional_dependencies": [],
			"tags": ["gameplay", "qol"]
		}
	},
	"name": "SmartThreadManager",
	"namespace": "kuuk",
	"version_number": "2.1.5",
	"website_url": "https://github.com/Omisse/ul-stmmod"
}
```

**Required state after edits** (per decisions D-02, D-04, D-05):
```json
{
	"dependencies": [],
	"description": "Smart distributor for CPU speed.",
	"extra": {
		"godot": {
			"authors": ["kuuk"],
			"compatible_game_version": [
				"2.1.8",
				"2.1.10"
			],
			"compatible_mod_loader_version": ["7.0.0", "7.0.1"],
			"config_schema": {},
			"description_rich": "",
			"image": null,
			"incompatibilities": [],
			"load_before": [],
			"optional_dependencies": [],
			"tags": ["gameplay", "qol"]
		}
	},
	"name": "SmartThreadManager",
	"namespace": "kuuk",
	"version_number": "2.1.10",
	"website_url": "https://github.com/Omisse/ul-stmmod"
}
```

**Changes (3 targeted edits):**
- Line 37: `"version_number": "2.1.5"` → `"version_number": "2.1.10"`
- Lines 9-16: Replace `compatible_game_version` array — remove 5 legacy entries (`2.0.0`, `2.0.17`, `2.0.19`, `2.0.20`, `2.0.21`), keep `2.1.8`, add `2.1.10`
- `compatible_mod_loader_version`: **no change** — `7.0.1` already present

---

### `kuuk-SmartGPUManager/manifest.json` (config, transform)

**Analog:** `kuuk-SmartThreadManager/manifest.json` — same schema, same edit pattern.

**Current state** (lines 1-39 of `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/manifest.json`):
```json
{
    "dependencies": [],
    "description": "Smart distributor for GPU speed.",
    "extra": {
        "godot": {
            "authors": ["kuuk"],
            "compatible_game_version": [
                "2.0.0",
                "2.0.17",
                "2.0.19",
                "2.0.20",
                "2.0.21",
                "2.1.8"
            ],
            "compatible_mod_loader_version": ["7.0.0", "7.0.1"],
            "config_schema": {},
            "description_rich": "",
            "image": null,
            "incompatibilities": [],
            "load_before": [],
            "optional_dependencies": [],
            "tags": ["gameplay", "qol"]
        }
    },
    "name": "SmartGPUManager",
    "namespace": "kuuk",
    "version_number": "2.1.5",
    "website_url": "https://github.com/Omisse/ul-stmmod"
}
```

**Required state after edits:**
```json
{
    "dependencies": [],
    "description": "Smart distributor for GPU speed.",
    "extra": {
        "godot": {
            "authors": ["kuuk"],
            "compatible_game_version": [
                "2.1.8",
                "2.1.10"
            ],
            "compatible_mod_loader_version": ["7.0.0", "7.0.1"],
            "config_schema": {},
            "description_rich": "",
            "image": null,
            "incompatibilities": [],
            "load_before": [],
            "optional_dependencies": [],
            "tags": ["gameplay", "qol"]
        }
    },
    "name": "SmartGPUManager",
    "namespace": "kuuk",
    "version_number": "2.1.10",
    "website_url": "https://github.com/Omisse/ul-stmmod"
}
```

**Changes (3 targeted edits — identical to STM):**
- `"version_number": "2.1.5"` → `"version_number": "2.1.10"`
- `compatible_game_version`: trim to `["2.1.8", "2.1.10"]`
- `compatible_mod_loader_version`: no change

---

## Shared Patterns

### ZIP Packaging Structure
**Source:** Verified against working `Bottlenecks.zip` (Steam Workshop item 3651033564)
**Apply to:** Both mod packaging steps

Required ZIP internal layout — `mods-unpacked/` must be the root-level folder inside the archive:
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

### ZIP Packaging Command
**Source:** PowerShell `Compress-Archive` built-in (Windows 11)
**Apply to:** Both mod ZIPs — run from the mod's parent directory so `mods-unpacked/` is at ZIP root

For SmartThreadManager — run from `C:\Users\Jake\Projects\Upload Smrt Nodes\Smrt Thread Manager\`:
```powershell
Compress-Archive -Path mods-unpacked -DestinationPath kuuk-SmartThreadManager.zip -Force
```

For SmartGPUManager — run from `C:\Users\Jake\Projects\Upload Smrt Nodes\Smrt GPU Manager\`:
```powershell
Compress-Archive -Path mods-unpacked -DestinationPath kuuk-SmartGPUManager.zip -Force
```

### Install Directory Creation
**Source:** Verified from `modloader.log` scan path behavior
**Apply to:** Pre-copy step — must be created before copying ZIPs

```powershell
New-Item -ItemType Directory -Force -Path "D:\Program Files (x86)\Steam\steamapps\common\Upload Labs\mods"
```

### ZIP Copy to Install Directory
**Apply to:** Both ZIPs after packaging

```powershell
Copy-Item "C:\Users\Jake\Projects\Upload Smrt Nodes\Smrt Thread Manager\kuuk-SmartThreadManager.zip" `
    -Destination "D:\Program Files (x86)\Steam\steamapps\common\Upload Labs\mods\"

Copy-Item "C:\Users\Jake\Projects\Upload Smrt Nodes\Smrt GPU Manager\kuuk-SmartGPUManager.zip" `
    -Destination "D:\Program Files (x86)\Steam\steamapps\common\Upload Labs\mods\"
```

### Verification Pattern
**Source:** `C:\Users\Jake\AppData\Roaming\Upload Labs\logs\modloader.log` — confirmed log format
**Apply to:** Post-launch verification step (D-06)

SUCCESS lines to check for:
```
SUCCESS kuuk:STM:Main: Initialized, version: 2.1.10
SUCCESS kuuk:SGM:Main: Initialized, version: 2.1.10
```

Absence of ERROR lines mentioning `kuuk-SmartThreadManager` or `kuuk-SmartGPUManager` is also required.

---

## No Analog Found

None. Both files being modified (manifest.json) are direct analogs of each other.

---

## Critical Decision Override (from RESEARCH.md)

**D-01 in CONTEXT.md says:** Copy raw mod folders to `mods-unpacked/`.
**RESEARCH.md overrides:** Loader does NOT scan `game_dir/mods-unpacked/` for loose folders. It scans `game_dir/mods/` for ZIP files only. The planner must implement ZIP packaging + `mods/` install, not loose folder copy.

**Evidence:** Four separate modloader.log sessions show the scan sequence as `res://mods-unpacked/` (virtual FS only) → `game_dir/mods/` (ZIP scan) → Steam Workshop. The `mods-unpacked/` directory on disk is never scanned.

---

## Order of Operations (critical — pitfall 4 avoidance)

Manifest edits MUST precede ZIP creation. If ZIPs are created first and manifests edited after, the ZIPs will contain stale manifests.

1. Edit `manifest.json` in STM source tree
2. Edit `manifest.json` in SGM source tree
3. Create `kuuk-SmartThreadManager.zip`
4. Create `kuuk-SmartGPUManager.zip`
5. Create `game_dir/mods/` directory
6. Copy both ZIPs to `game_dir/mods/`
7. Launch game and verify via modloader.log

---

## Metadata

**Analog search scope:** `C:\Users\Jake\Projects\Upload Smrt Nodes\` (both mod source trees)
**Files scanned:** 2 manifest.json files read directly
**Pattern extraction date:** 2026-04-16
