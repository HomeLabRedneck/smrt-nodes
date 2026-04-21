# Working Mod Patterns (2.1.10)

Researched: 2026-04-16
Source repo: https://github.com/Omisse/ul-stmmod

---

## Confirmed Working API (from working mods)

### ResourceContainer properties (confirmed in use by working mods)

| Property | Type | Source | Notes |
|----------|------|--------|-------|
| `count` | float | SmartThreadManager 1.0.7 (old), BetterSplitters, Bottlenecks | Read/write. Current resource amount held. |
| `production` | float | SmartThreadManager 1.0.7, Bottlenecks | Read only. Confirmed via `container.production`. |
| `required` | float | SmartThreadManager 1.0.7, Bottlenecks | Read only. Confirmed via `container.required`. |
| `outputs` | Array[ResourceContainer] | BetterSplitters | `output.outputs.is_empty()` — outputs is an array property on a container. |
| `id` | unknown | SmartThreadManager 1.0.7 | Referenced as `rc.id` when building window data. |
| `type` | unknown | SmartThreadManager 2.1.5 (stm_window_data) | Referenced as `c.type`. |
| `looping` | Array[ResourceContainer] | SmartThreadManager 1.0.7 AND 2.1.5 | **Both old and new versions use `looping`.** Used as `for i: ResourceContainer in looping: i.count = 0`. This is confirmed working in 2.1.5. |
| `transfer` | Array[ResourceContainer] | SmartThreadManager 1.0.7 | Used as `_bind_windows(transfer)` — an array of ResourceContainers representing inputs. Also used as `target_inputs: Array[ResourceContainer]` in `_update_wdata(transfer, state.wdata)` in v2.1.5. **`transfer` is used in BOTH versions.** |

### ResourceContainer methods (confirmed working)

| Method | Source | Notes |
|--------|--------|-------|
| `pop(amount)` | BetterSplitters | `input.pop(amount)` |
| `pop_all()` | BetterSplitters | `input.pop_all()` |
| `add(amount)` | BetterSplitters | `output.add(amount)` |

### ResourceContainer signals (confirmed working)

| Signal | Source | Notes |
|--------|--------|-------|
| `connection_out_set` | BetterSplitters | `output.connection_out_set` |

### ResourceContainer sub-properties (confirmed working)

| Property | Source | Notes |
|----------|--------|-------|
| `input.resource` | BetterSplitters | The resource object held in a container |
| `input.variation` | BetterSplitters | Variation property of the resource |

### Window properties (confirmed working)

| Property | Source | Notes |
|----------|--------|-------|
| `containers` | SmartThreadManager 1.0.7 AND 2.1.5 | `window.containers` — array of ResourceContainers on the window. Filtered with `.filter(func(c): return c.is_in_group("input"))`. |
| `goal` | SmartThreadManager 1.0.7, Bottlenecks | `window.goal` — checked with `"goal" in window` before access (Bottlenecks). In v1.0.7, `_get_goal()` uses `window.goal if "goal" in window else 0.0`. In v2.1.5, `window.demand` and `window.goal` are accessed via `"demand" in window` and `"goal" in window` checks. |
| `demand` | SmartThreadManager 2.1.5 | `window.demand` — checked with `"demand" in window` before access. New in 2.1.5 API. |
| `name` | SmartThreadManager 2.1.5 | `window.name` — used as dictionary key for wdata. |

### Window group membership (confirmed working)

- Windows belong to the `"window"` group (`is_in_group("window")`)
- Input containers belong to the `"input"` group (`c.is_in_group("input")`)

### Method overrides (confirmed working in 2.1.5)

| Method | Notes |
|--------|-------|
| `tick()` | Overridden in SmartResourceContainer. Calls `super()` implied (does not call it directly — the override replaces the base tick entirely). Uses `looping` and calls distribution logic. CONFIRMED WORKING in 2.1.5. |
| `update_connections()` | Overridden with `super()` call in 2.1.5. Sets `data_changed = true`. CONFIRMED WORKING. |
| `_ready()` | Overridden with `super()` call. CONFIRMED WORKING. |

### Type reference (confirmed working)

- `extends ResourceContainer` — direct class name extension works in 2.1.5 (not a path-based extend like v1.0.7 used)
- v1.0.7 used: `class_name SmartResourceContainer extends "res://scenes/resource_container.gd"` — path-based string extend
- v2.1.5 uses: `extends ResourceContainer` — global class name extend
- `WindowBase` — base class for windows, used in type hints

---

## Suspected Changed API

### What changed between v1.0.7 and v2.1.5 of SmartThreadManager

The most important finding is the **extend syntax change**:

- **OLD (1.0.7, broke in 2.1+):** `class_name SmartResourceContainer extends "res://scenes/resource_container.gd"`
  - Extends by file path string
  - Used `class_name` declaration
  - The Godot Mod Loader docs explicitly state: "Script Extensions will not be applied to scripts that are preloaded in any way" and "you cannot extend global classes (scripts with `class_name` declarations)"
  
- **NEW (2.1.5, works in 2.1.10):** `extends ResourceContainer`
  - Extends by global class name directly (no `class_name` declaration on the mod's own class)
  - No `class_name` on the extending script itself

**Hypothesis about the 2.1+ crash:** The game likely changed `ResourceContainer` from a path-referenced script to a proper globally-registered class (`class_name ResourceContainer`). This broke path-based string extends like `extends "res://scenes/resource_container.gd"`. The fix was to switch to `extends ResourceContainer` (extend by class name). This is consistent with the commit message "global classes are now instances in main" visible in the compare diff.

### Architecture differences between versions

**v1.0.7 approach (broken):**
- `class_name SmartResourceContainer extends "res://scenes/resource_container.gd"`
- `_bind_windows(transfer)` — used `transfer` directly as the input array
- `window.containers` — accessed directly 
- Nested `WindowBase` and `InputContainerData` classes inside same file
- Called `Signals.new_upgrade.connect(...)` — relied on a global `Signals` singleton
- Called `should_tick()` — a method on ResourceContainer not seen in v2.1.5

**v2.1.5 approach (working):**
- `extends ResourceContainer` — no class_name on the extending script
- `transfer` still used — passed as `_update_wdata(transfer, state.wdata)`
- `looping` still used — `for i: ResourceContainer in looping: i.count = 0`
- Architecture refactored to external helper scripts (`STMWindowData`, `STMWindowGraph`, `STMUtils`, `STMDistribution`)
- `update_connections()` override with `super()` + sets `data_changed = true` flag
- No longer calls `Signals.new_upgrade` directly
- No longer calls `should_tick()` — removed

### Properties/methods NOT seen in working 2.1.5 code

These were used in v1.0.7 and are ABSENT from v2.1.5 — their status in 2.1.10 is unknown:

| Property/Method | Last seen in | Status |
|-----------------|-------------|--------|
| `should_tick()` | v1.0.7 | REMOVED from mod — may no longer exist on ResourceContainer in 2.1+ |
| `Signals.new_upgrade` | v1.0.7 | REMOVED from mod — unknown if still exists as global singleton |
| `WindowBase` type | Both versions | Used in type hints — still present in 2.1.5 |
| Path-based extend | v1.0.7 | BROKEN in 2.1+ — do not use |

---

## Community Discussion

### Steam Discussion: "Game Crash on open"
URL: https://steamcommunity.com/app/3606890/discussions/0/762932162500648528/

- Multiple users reported game crash on launch after a game update (around February 8–9, 2026, versions 2.1.8–2.1.10)
- Root cause confirmed as Smart Thread Manager and Smart GPU Manager mods
- Workaround: unsubscribe from all mods, or roll back to game version 2.0 via Steam
- Fix confirmed by original poster on February 9: "Smart Thread Manager & Smart GPU Manager are now working and my save is now opening"
- The fix coincided with the mod's 2.1.5 release on February 8, 2026

### Workshop Mod Compatibility Status
All 30 visible mods on the Upload Labs Steam Workshop show an "incompatible" badge as of research date (April 2026). This appears to be a systemic issue — possibly the game's Godot Mod Loader version requirement has bumped, or the game updated past what all mods declare as their max supported version in manifest.json. The Smart Thread Manager and GPU Manager mods show 4-star ratings and high subscriptions but also show incompatible.

- The Godot Mod Loader validates compatibility via the manifest's `game_version` field and can auto-disable mods when MAJOR versions increment.
- The mod's manifest.json states `"Upload Labs 2.0.17+ Mod Loader 7.0.0+"` as requirements — this minimum requirement predates 2.1.x, so the "incompatible" flag is likely from the workshop's compatibility metadata, not from the mod loader itself crashing.

### Key timeline reconstruction
- Game updated to 2.1.x (approximately 2.1.8 or 2.1.9 in early February 2026)
- SmartThreadManager and SmartGPUManager began crashing on load
- Mod author (kuuk / Omisse) released version 2.1.5 of the mod on February 8, 2026
- Version 2.1.5 release notes: "Fixed UL 2.1+ instant crash"
- February 9, 2026: users confirmed both mods working again (same day as game version 2.1.10)

---

## Original Mod Repo Findings

Repository: https://github.com/Omisse/ul-stmmod

### Repository structure
```
ul-stmmod/
├── .github/ISSUE_TEMPLATE/
├── details/
├── scenes/windows/
├── scripts/
│   ├── global/
│   │   ├── distribution_modes.gd
│   │   ├── stm_utils.gd
│   │   ├── stm_window_data.gd
│   │   ├── stm_window_graph.gd
│   │   └── window_graph.gd
│   ├── option_desktop_button.gd
│   ├── smart_resource_container.gd   ← KEY FILE
│   └── toggle_desktop_button.gd
├── translations/
├── manifest.json
└── mod_main.gd
```

### Releases
- **v2.1.5** (Feb 8, 2026) — Current. "Fixed UL 2.1+ instant crash." Added ratio/demand/graph modes.
- **v1.0.7** (Dec 30, 2025) — Previous. Slight optimizations, added GPU version attachment.
- **v1.0.6-release** (Dec 28, 2025) — Fixed on-connection crash and infinite stabilization edge-case.

### Issues
- Only 1 issue visible (Issue #4: "Download and Upload" by MrGallixy, Feb 24 2026) — a feature request marked "wontfix" asking for download/upload speed management
- No issues about 2.1.10, tick, looping, or transfer

### Core finding from source code comparison

The `smart_resource_container.gd` file is the central file that extends ResourceContainer. Comparing versions:

**v1.0.7 (BROKEN in 2.1+):**
```gdscript
class_name SmartResourceContainer extends "res://scenes/resource_container.gd"
```
Used: `transfer`, `looping`, `window.containers`, `window.goal`, `should_tick()`, `Signals.new_upgrade`

**v2.1.5 (WORKING in 2.1.10):**
```gdscript
extends ResourceContainer
```
Used: `transfer`, `looping`, `window.containers`, `window.goal`, `window.demand`, `window.name`, `super()` in `update_connections()` and `_ready()`

**The breaking change was the extend syntax**, not the `tick()`, `looping`, or `transfer` properties themselves. Those properties still exist and still work in 2.1.10. The fix was switching from path-string-based extending to class-name-based extending.

### Additional API confirmed from stm_window_data.gd (v2.1.5)
- `window.containers` — filtered for `c.is_in_group("input")`
- `container.id` — unique identifier per container
- `container.type` — resource type
- `container.production` — current production value
- `container.count` — current count (read/write)
- `container.required` — required amount
- `"demand" in window` — safe check before accessing window.demand
- `"goal" in window` — safe check before accessing window.goal
- Windows have a `STMWindowRoles` classification system: ARTIFACT, CONSUMER, STORAGE, MANAGER (mod-defined, based on goal/demand presence)
