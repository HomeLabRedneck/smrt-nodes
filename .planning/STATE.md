---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: Complete
last_updated: "2026-04-19T00:00:00.000Z"
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State — Upload Labs Smrt Nodes Mod Fix

## Project Reference

**Core value**: Both mods load, render, and correctly redistribute resources to connected downstream windows in Upload Labs 2.1.10
**Milestone**: Fix (single milestone)

---

## Current Position

Phase: 2 — COMPLETE
Plan: All plans complete
**Status**: Done
**Progress**: [██████████] 100%

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases total | 2 |
| Phases complete | 2 |
| Requirements total | 10 |
| Requirements complete | 10 |

## Performance Metrics (detail)

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01 P01 | 5m | 2 tasks | 2 files |
| Phase 01 P02 | 5m | 2 tasks | 4 files |
| Phase 02 P01 | ~10m | 3 tasks | manifests + ZIPs |
| Phase 02 P02 | ~15m | 3 tasks | smart_resource_container.gd x2 |
| Phase 02 P03 | ~45m | 3 tasks | shims + graph fix + verification |

## Accumulated Context

### Key Decisions

- `connection_out_set` signal hook + tick fallback = core fix. `update_connections()` was not firing on load; signal hook ensures it fires when outputs are set.
- ZIP base = mod parent directory (e.g. `Smrt Thread Manager/`), NOT `mods-unpacked/`. Wrong base silently breaks mod loader.
- `.NET ZipArchive` with `path.Replace('\','/')` required — never `Compress-Archive` (backslash paths).
- `state.demand = value` when no consumers (storage-only) — progress bar shows available resource.
- count-based demand fallback removed — `inputs[n].count` as proxy creates feedback loop in Graph mode. Use `required` if available, else `1.0` constant.
- Pure-storage windows (single resource input from STM) get equal distribution in all modes — by design.
- `[STM-DIAG]` prints in godot.log come from `Upload Labs.exe` binary, NOT the mod.
- Both mods share same fix pattern — applied in parallel throughout.

### Known Facts

- Game install: `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/`
- STM installed: `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartThreadManager.zip`
- SGM installed: `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/mods/kuuk-SmartGPUManager.zip`
- Demand/Graph modes differentiate only when downstream windows have multi-resource dependencies (e.g. Virus Scanner, Quarantine for STM)

### Blockers

None. Project complete.

---

## Session Continuity

**Last updated**: 2026-04-19
**Last action**: Phase 2 Plan 03 complete — all 14 verification conditions passed. Both mods working in 2.1.10.
**Next action**: None — milestone complete.
