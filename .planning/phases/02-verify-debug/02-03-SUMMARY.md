---
phase: 02-verify-debug
plan: "03"
subsystem: compatibility-shims-packaging
tags: [gdscript, shims, compatibility, packaging, zip, install]
dependency_graph:
  requires: [02-02 fix applied (connection_out_set hook + tick fallback)]
  provides: [both mods with compatibility shims, both mods repackaged + installed, human verification checkpoint]
  affects: [final FUNC-01..04 sign-off, CODE-01 satisfied]
tech_stack:
  added: []
  patterns:
    - "has()/get() defensive property access pattern for Godot game API compatibility"
    - ".NET System.IO.Compression.ZipFile with forward-slash entry paths"
key_files:
  created: []
  modified:
    - "Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/smart_resource_container.gd"
    - "Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/smart_resource_container.gd"
    - "Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/global/stm_window_data.gd"
    - "Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/global/stm_window_data.gd"
    - "Smrt Thread Manager/kuuk-SmartThreadManager.zip"
    - "Smrt GPU Manager/kuuk-SmartGPUManager.zip"
    - "D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartThreadManager.zip"
    - "D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartGPUManager.zip"
decisions:
  - "Relaxed _update_wdata() parameter type from Array[ResourceContainer] to Array to allow shim-guarded assignment"
  - "ZIP repackaged with .NET ZipArchive forward-slash paths (vs prior Compress-Archive backslash) — more portable"
  - "Removed count-based demand fallback — inputs[n].count as demand proxy creates feedback loop in Graph mode"
  - "Pure-storage windows (single resource input from STM) get equal distribution in all modes — by design, not a bug"
  - "[STM-DIAG] prints in godot.log come from Upload Labs.exe binary, NOT the mod — grep confirmed"
metrics:
  duration: "~45 minutes"
  completed: "2026-04-19"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 7
---

# Phase 02 Plan 03: Compatibility Shims, Diagnostics Removal, and Repackage Summary

**Compatibility shims added to both mods, graph mode feedback-loop bug fixed, diagnostic prints removed, both mods repackaged and installed — all 14 verification conditions passed.**

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add compatibility shims and remove diagnostic prints (both mods) | 88d89d2 | smart_resource_container.gd x2, stm_window_data.gd x2 |
| 2 | Repackage and install both mods with shims | 72dd8f8 | kuuk-SmartThreadManager.zip, kuuk-SmartGPUManager.zip (source + game install) |
| 3 | Full verification — all modes, edge cases, UI updates | (checkpoint — awaiting human) | n/a |

---

## Task 1: Shim Details

### smart_resource_container.gd (both STM and SGM)

| Property | Guard applied | Fallback |
|----------|--------------|---------|
| `transfer` | `transfer if "transfer" in self else []` | `[]` |
| `looping` | `looping if "looping" in self else []` | `[]` |
| `count` | `count if "count" in self else 0.0` | `0.0` |

- `_update_wdata()` signature relaxed from `Array[ResourceContainer]` to `Array` to allow shimmed assignment
- `_update_windows()` now reads `_transfer` local before passing to `_update_wdata()`
- Tick fallback reworked: reads `_transfer` shim-guarded, re-reads after `update_connections()` call

### stm_window_data.gd (both STM and SGM — STMContainerData inner class)

| Property | Guard applied | Fallback |
|----------|--------------|---------|
| `window.containers` | `window.containers if "containers" in window else []` | `[]` |
| `container.id` | `container.id if "id" in container else str(container.get_instance_id())` | instance ID string |
| `c.type` in `_is_material` | `if "type" not in c: return false` | returns false (not material) |
| `container.production` in `get_prod()` | `container.production if "production" in container else 0.0` | `0.0` |
| `container.count` in `get_count()` | `container.count if "count" in container else 0.0` | `0.0` |
| `container.required` in `_get_multi()` | `container.required if "required" in container else 1.0` | `1.0` (neutral multiplier) |

- `window.goal` — already shimmed via `"goal" in window` dynamic check in get_goal() — no change
- `window.demand` — mod's OWN property, not a game API property — no shim needed

### Preserved (not removed)

- `connection_out_set.connect(func(): update_connections())` in `_ready()` — core fix from 02-02
- Tick-time fallback: `if _transfer.is_empty() and not outputs.is_empty(): update_connections()` — required

### Diagnostic prints removed

- All `print("[STM-DIAG] ...")` lines — 4 lines removed from STM smart_resource_container.gd
- All `print("[SGM-DIAG] ...")` lines — 4 lines removed from SGM smart_resource_container.gd
- `# DIAGNOSTIC -- remove after fix confirmed` comment block removed

---

## Task 2: Repackaging Details

| File | Size | First entry | Entry path style |
|------|------|-------------|-----------------|
| STM source ZIP | 18,496 bytes | `mods-unpacked/kuuk-SmartThreadManager/manifest.json` | forward slash |
| SGM source ZIP | 18,542 bytes | `mods-unpacked/kuuk-SmartGPUManager/manifest.json` | forward slash |
| STM installed | 18,496 bytes | D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/ | — |
| SGM installed | 18,542 bytes | D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/ | — |

Packaging method: `System.IO.Compression.ZipFile` with explicit `entry.Replace('\', '/')` — all entries use forward slashes. Prior Phase 1 Plan 02 used Compress-Archive (backslash paths); this plan upgrades to forward-slash for improved cross-platform portability.

Spot-check: extracted `smart_resource_container.gd` from STM ZIP confirmed `"transfer" in self` shim present.

---

## Graph Mode Bug Fix (de027d4)

Discovered during verification: switching to Graph mode caused demand to drop to 0Hz, and switching back to Demand mode left demand stuck at 0.

**Root cause:** `get_demand()` and `get_count_demand()` in `stm_window_data.gd` used `inputs[n].count` as demand proxy when `required` was unavailable. Graph mode reduces allocation → count drops → demand drops → even less allocation → feedback loop stabilizing near 0.

**Fix:** Removed count-based fallback. Now falls back to `1.0` constant instead.

SGM unaffected — uses goal-based demand (different architecture, no feedback loop).

---

## Task 3: 14-Point Verification Results

All 14 conditions passed (2026-04-19).

| # | Condition | Result | Notes |
|---|-----------|--------|-------|
| 1 | STM Ratio mode | ✅ | Equal shares, progress bar non-zero |
| 2 | STM Demand mode | ✅ | Proportional with multi-resource windows (Virus Scanner, Quarantine) |
| 3 | STM Graph mode | ✅ | Real Hz demand, no 0Hz stuck |
| 4 | STM Progress bar + demand label | ✅ | Updates live, non-zero |
| 5 | STM 0 upstream | ✅ | No crash |
| 6 | STM Single downstream | ✅ | Gets 100% |
| 7 | STM Empty graph | ✅ | No crash, distributes equally |
| 8 | SGM Ratio mode | ✅ | Equal shares, progress bar non-zero |
| 9 | SGM Demand mode | ✅ | Correct for window type (Miner, Scheduler are single-resource → equal by design) |
| 10 | SGM Graph mode | ✅ | Working |
| 11 | SGM Progress bar + demand label | ✅ | Updates live |
| 12 | SGM 0 upstream | ✅ | No crash |
| 13 | SGM Single downstream | ✅ | Gets 100% |
| 14 | SGM Empty graph | ✅ | No crash |

**Behavior note:** Demand and Graph modes distribute equally when downstream windows have only ONE resource input (all from STM). This is correct — those windows are classified `STM_STORAGE` and receive equal shares of remainder. Modes differentiate when windows have additional non-STM resource dependencies (e.g. Virus Scanner, Quarantine for STM).

---

## Deviations from Plan

**1. [Rule 1 - Bug] Relaxed _update_wdata() parameter type**
- Found during: Task 1 implementation
- Issue: Assigning a shim-guarded `Array` local to a parameter typed `Array[ResourceContainer]` would cause a type error in GDScript; the function only calls `.map()` and `.filter()` — no typed operations
- Fix: Changed `target_inputs: Array[ResourceContainer]` to `target_inputs: Array` in both mods
- Files modified: both smart_resource_container.gd files
- Commit: 88d89d2

**2. [Rule 3 - Blocking] Plan Task 2 incorrectly referenced Compress-Archive**
- Plan text said "use same PowerShell method from Phase 1 Plan 02" but critical_constraints override specified .NET ZipArchive
- Used .NET ZipArchive as directed by critical_constraints — forward-slash entry paths confirmed

---

## Known Stubs

None — all data paths are wired. Shim fallbacks produce safe no-op values (empty arrays, 0.0) rather than placeholder UI text.

---

## Self-Check: PASSED

- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/smart_resource_container.gd` — FOUND
- `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/smart_resource_container.gd` — FOUND
- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/global/stm_window_data.gd` — FOUND
- `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/global/stm_window_data.gd` — FOUND
- `Smrt Thread Manager/kuuk-SmartThreadManager.zip` — FOUND (18,496 bytes)
- `Smrt GPU Manager/kuuk-SmartGPUManager.zip` — FOUND (18,542 bytes)
- Commits 88d89d2 and 72dd8f8 — FOUND in git log
- No [STM-DIAG] or [SGM-DIAG] strings in source files — CONFIRMED
- connection_out_set signal hook line 45 in both smart_resource_container.gd — CONFIRMED
