# Upload Labs Smrt Nodes — Mod Fix

## What This Is

Fix two broken Upload Labs mods — **SmartThreadManager** and **SmartGPUManager** — so they work with game version 2.1.11. Both mods were authored by `kuuk` and published on Steam Workshop. They provide "smart" auto-distribution of CPU thread speed and GPU speed respectively, letting players set up automatic load-balancing across connected windows.

**Core value:** Both mods load, render, and accept connections in 2.1.11 — but the distribution logic does nothing. The fix restores the actual smart-allocation behavior.

## Context

- **Game:** Upload Labs (Godot 4, GodotModLoader 7.x)
- **Broken since:** Game updated from 2.1.8 → 2.1.10
- **Symptom:** Mods initialize without errors, windows appear and accept connections, but `smart_resource_container.tick()` either isn't called or operates on stale/empty state — so no resource redistribution occurs
- **Root cause (hypothesis):** The game's `ResourceContainer` base class API changed between 2.1.8 and 2.1.10. The mods rely on inherited properties (`looping`, `transfer`) and a `tick()` method override that may have been renamed or restructured
- **Source location:** `C:\Users\Jake\Projects\Upload Smrt Nodes\`
  - `Smrt Thread Manager\mods-unpacked\kuuk-SmartThreadManager\`
  - `Smrt GPU Manager\mods-unpacked\kuuk-SmartGPUManager\`
  - `ul-stmmod-2.1.5\` — upstream reference source

## Key Files

| File | Purpose |
|------|---------|
| `scripts/smart_resource_container.gd` | Extends `ResourceContainer`, overrides `tick()` and `update_connections()` — most likely broken here |
| `scripts/global/stm_window_data.gd` | Classifies connected windows as consumer/manager/storage; uses `window.containers` and `container.id` |
| `scripts/global/distribution_modes.gd` | Pure distribution math — unlikely to be broken |
| `scenes/windows/window_smart_thread_manager.gd` | Window UI; calls `output.count = input.count` in `process()` |
| `manifest.json` | Needs `2.1.10` added to `compatible_game_version` |

## Requirements

### Active

- [ ] Decompile the game EXE to extract current `ResourceContainer` API (properties, method names)
- [ ] Identify all API mismatches between what the mods use and what the game now provides
- [ ] Fix `smart_resource_container.gd` to use the current API
- [ ] Fix `stm_window_data.gd` if `window.containers` or `container.id` changed
- [ ] Fix `window_smart_thread_manager.gd` and `window_smart_gpu_manager.gd` if needed
- [ ] Update `manifest.json` in both mods to include `2.1.10` in `compatible_game_version`
- [ ] Both mods must correctly redistribute resources to connected downstream windows

### Out of Scope

- Merging the two mods into one — noted in the log ("One day i will merge this") but not the task
- New features beyond restoring original behavior
- UI changes

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Decompile game to get API | No game source available; other modders do this; only way to know exactly what changed | — Pending |
| Fix both mods in parallel | They share the same `smart_resource_container.gd` pattern | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition:**
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions

---
*Last updated: 2026-04-16 after initialization*
