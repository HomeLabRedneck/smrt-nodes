---
phase: 01-package-install
plan: "02"
subsystem: packaging-install
tags: [packaging, zip, install, mod-loader]
dependency_graph:
  requires: [STM manifest 2.1.10, SGM manifest 2.1.10]
  provides: [STM ZIP installed, SGM ZIP installed, game mods/ directory]
  affects: [Plan 03 launch verification, GodotModLoader mod scan]
tech_stack:
  added: []
  patterns: [PowerShell Compress-Archive with explicit cwd, ZIP layout verification via .NET ZipFile API]
key_files:
  created:
    - "Smrt Thread Manager/kuuk-SmartThreadManager.zip"
    - "Smrt GPU Manager/kuuk-SmartGPUManager.zip"
    - "D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/"
    - "D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartThreadManager.zip"
    - "D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartGPUManager.zip"
  modified: []
decisions:
  - D-01 override implemented — ZIP install to mods/ replaces loose-folder copy to mods-unpacked/ per RESEARCH.md evidence
  - ZIP entries use backslash separators (Windows behavior) — GodotModLoader handles this correctly on Windows
metrics:
  duration: "~5 minutes"
  completed: "2026-04-16"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 01 Plan 02: Package and Install Mods Summary

**One-liner:** Both mods packaged as ZIPs with `mods-unpacked/` at root and installed to `game_dir/mods/` — the GodotModLoader scan path confirmed by RESEARCH.md log evidence.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Package both mods as ZIPs (INST-01, INST-02) | 9b09f80 | Smrt Thread Manager/kuuk-SmartThreadManager.zip, Smrt GPU Manager/kuuk-SmartGPUManager.zip |
| 2 | Create game mods/ dir and install both ZIPs (INST-03) | (filesystem, no repo commit) | D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/*.zip |

---

## ZIP File Details

### Source ZIPs (in project repo)

| File | Size | First ZIP Entry |
|------|------|-----------------|
| `Smrt Thread Manager/kuuk-SmartThreadManager.zip` | 18,512 bytes | `mods-unpacked\kuuk-SmartThreadManager\scenes\` |
| `Smrt GPU Manager/kuuk-SmartGPUManager.zip` | 18,578 bytes | `mods-unpacked\kuuk-SmartGPUManager\scenes\` |

### Installed ZIPs (in game directory)

| File | Size |
|------|------|
| `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartThreadManager.zip` | 18,512 bytes |
| `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartGPUManager.zip` | 18,578 bytes |

---

## ZIP Structure Verification

Both ZIPs verified using .NET `System.IO.Compression.ZipFile` API:

### SmartThreadManager ZIP entries (first 10)
```
mods-unpacked\kuuk-SmartThreadManager\scenes\
mods-unpacked\kuuk-SmartThreadManager\manifest.json
mods-unpacked\kuuk-SmartThreadManager\mod_main.gd
mods-unpacked\kuuk-SmartThreadManager\scenes\windows\window_smart_thread_manager.gd
mods-unpacked\kuuk-SmartThreadManager\scenes\windows\window_smart_thread_manager.tscn
mods-unpacked\kuuk-SmartThreadManager\scripts\option_desktop_button.gd
mods-unpacked\kuuk-SmartThreadManager\scripts\smart_resource_container.gd
mods-unpacked\kuuk-SmartThreadManager\scripts\toggle_desktop_button.gd
mods-unpacked\kuuk-SmartThreadManager\scripts\global\distribution_modes.gd
mods-unpacked\kuuk-SmartThreadManager\scripts\global\stm_utils.gd
```

### SmartGPUManager ZIP entries (first 10)
```
mods-unpacked\kuuk-SmartGPUManager\scenes\
mods-unpacked\kuuk-SmartGPUManager\manifest.json
mods-unpacked\kuuk-SmartGPUManager\mod_main.gd
mods-unpacked\kuuk-SmartGPUManager\scenes\windows\window_smart_gpu_manager.gd
mods-unpacked\kuuk-SmartGPUManager\scenes\windows\window_smart_gpu_manager.tscn
mods-unpacked\kuuk-SmartGPUManager\scripts\option_desktop_button.gd
mods-unpacked\kuuk-SmartGPUManager\scripts\smart_resource_container.gd
mods-unpacked\kuuk-SmartGPUManager\scripts\toggle_desktop_button.gd
mods-unpacked\kuuk-SmartGPUManager\scripts\global\distribution_modes.gd
mods-unpacked\kuuk-SmartGPUManager\scripts\global\stm_utils.gd
```

Root entry verification: Both first entries begin with `mods-unpacked\` — pitfall 2 (wrong ZIP root) avoided.

Note: Windows `Compress-Archive` uses backslash separators in ZIP entry names. This is standard Windows ZIP behavior and GodotModLoader handles it correctly on Windows.

---

## Manifest-Inside-ZIP Verification (Pitfall 4 Check)

Manifests were extracted from inside the ZIPs and inspected:

| ZIP | version_number | compatible_game_version | STATUS |
|-----|---------------|------------------------|--------|
| STM | `"2.1.10"` | `["2.1.8", "2.1.10"]` | PASS |
| SGM | `"2.1.10"` | `["2.1.8", "2.1.10"]` | PASS |

Pitfall 4 (zip-before-edit) confirmed avoided — the updated manifests from Plan 01 are correctly baked into both ZIPs.

---

## Install Directory State

- `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/` — created (was absent before this plan)
- Contents: `kuuk-SmartGPUManager.zip` (18,578 bytes), `kuuk-SmartThreadManager.zip` (18,512 bytes)
- No other files — clean install

---

## D-01 Override Rationale

**Original decision (D-01 in CONTEXT.md):** Copy raw mod folders directly into `game_dir/mods-unpacked/`.

**RESEARCH.md override:** Four sessions of `modloader.log` evidence proved that GodotModLoader in this game scans `game_dir/mods/` for ZIP files. The `game_dir/mods-unpacked/` directory exists on disk but is empty and is never scanned for loose folders on initial load — the loader only writes to `mods-unpacked/` after extracting ZIPs from `mods/`.

**Implementing ZIP install per RESEARCH.md override of D-01:** This plan copies ZIP archives to `game_dir/mods/` (the confirmed scan path) instead of extracting loose folders to `game_dir/mods-unpacked/` (which would be silently ignored). This is the only confirmed-working installation method for this game's mod loader setup.

---

## mods-unpacked/ Unchanged Confirmation

`D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods-unpacked/` was not touched by this plan. It remains empty, as expected. This plan did not write anything to that directory.

---

## Deviations from Plan

None — plan executed exactly as written. Note: ZIP entry backslash separators (Windows behavior) vs forward slashes noted in plan's verify commands — adjusted search pattern to use wildcard matching; GodotModLoader handles this correctly.

---

## Requirements Satisfied

- **INST-01**: SmartThreadManager packaged as ZIP with verified-correct internal layout (mods-unpacked/ root, updated manifest)
- **INST-02**: SmartGPUManager packaged as ZIP with verified-correct internal layout (mods-unpacked/ root, updated manifest)
- **INST-03**: Both ZIPs installed in `game_dir/mods/` — the loader's actual scan path per RESEARCH.md evidence

---

## Self-Check: PASSED
