---
phase: 02-verify-debug
plan: "02"
subsystem: infra
tags: [godot, gdscript, resource-container, diagnostics, fix]

requires:
  - phase: 02-01-verify-debug
    provides: mods installed and visible in game; baseline confirmed broken

provides:
  - Root cause identified: update_connections() override not called by game engine
  - Fix applied: connection_out_set signal hook + tick-time fallback in both mods
  - Both mods repackaged and installed with fix
  - transfer now populates correctly (transfer=2 confirmed in diagnostic log)

affects: [02-03-verify-debug]

tech-stack:
  added: []
  patterns:
    - "connection_out_set signal + tick fallback pattern for ResourceContainer subclasses"

key-files:
  modified:
    - "Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/smart_resource_container.gd"
    - "Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/smart_resource_container.gd"

key-decisions:
  - "Root cause: game engine _on_create_connection() does not dispatch update_connections() to GDScript override on output container"
  - "Fix: hook connection_out_set signal in _ready() + tick-time fallback — mirrors BetterSplitters reference mod pattern"
  - "Thread Manager downstream windows classify as STM_STORAGE (role=2) — clock_speed is FLOW type, not MATERIAL; demands=0.0 is correct; equal-split via _set_storages() applies"
  - "Diagnostic prints still present — to be removed in Plan 02-03"

patterns-established:
  - "ResourceContainer subclass: always hook connection_out_set signal + tick fallback — game dispatch is unreliable"

requirements-completed: [FUNC-01, FUNC-02]

duration: 60min
completed: 2026-04-19
---

# Phase 02-02: Diagnostics + Root Cause Fix Summary

**Identified and fixed update_connections() dispatch failure via connection_out_set signal hook; transfer now populates (0→2) and distribution pipeline executes**

## Performance

- **Duration:** ~60 min
- **Completed:** 2026-04-19
- **Tasks:** 2 (Task 1: add diagnostics; Task 2: identify root cause + apply fix)
- **Files modified:** 2

## Accomplishments

- Added `[STM-DIAG]`/`[SGM-DIAG]` diagnostic prints to both mods' `smart_resource_container.gd`
- Captured diagnostic log: `transfer=0, looping=0, wdata={}` on every tick — transfer never filled
- Traced root cause: `update_connections()` GDScript override was never called by game engine's `_on_create_connection()` handler for this container type
- Cross-referenced with BetterSplitters reference mod — it uses `connection_out_set` signal directly
- Applied fix: `connection_out_set.connect(func(): update_connections())` in `_ready()` + tick fallback
- Confirmed fix: `transfer=2, wdata=[thread_manager8, thread_manager11]` in next diagnostic log
- Diagnosed `demands=0.0` — expected behavior: Thread Manager windows have no material inputs (`clock_speed` is FLOW type=1), so `dependent=[]` → STM_STORAGE role → equal-split via `_set_storages()`

## Task Commits

- Diagnostics + fix applied to working tree (uncommitted — pending Plan 02-03 cleanup commit)

## Files Created/Modified

- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/smart_resource_container.gd` — diagnostics + connection_out_set fix + tick fallback
- `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/smart_resource_container.gd` — same with SGM prefix

## Decisions Made

- `connection_out_set` signal chosen over engine dispatch — matches BetterSplitters reference mod
- `demands=0.0` for Thread Manager windows is correct — STM_STORAGE equal-split is the intended behavior for ratio mode with clock_speed resources

## Deviations from Plan

**1. Fix applied inline during Task 2 (not deferred to Plan 02-03)**
- Task 2 only required root cause identification per plan spec
- Fix was obvious from root cause — applied immediately to unblock Plan 02-03
- No additional scope; Plan 02-03 still owns: remove diagnostics, add compat shims, full verification

## Issues Encountered

- `transfer` always 0: game engine dispatch failure (see root cause above)
- `demands=0.0`: initially appeared as a bug; traced to correct STM_STORAGE classification

## Next Phase Readiness

- Fix confirmed via diagnostic log: transfer=2, wdata populated
- Diagnostic prints must be removed in Plan 02-03
- Compatibility shims (has()/get() guards) must be added in Plan 02-03
- Full 14-point in-game verification pending

---
*Phase: 02-verify-debug*
*Completed: 2026-04-19*
