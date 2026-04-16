# Phase 2: Verify & Debug — Research

**Researched:** 2026-04-16
**Domain:** Upload Labs 2.1.11 ResourceContainer API + GDScript mod behavior
**Confidence:** HIGH (decompiled game source confirmed; all key claims verified against `resource_container.gd` from live EXE)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Try Workshop mods first, then wiki, then decompile (investigation order)
- **D-02:** Use wiki.godotmodding.com if Workshop mods don't cover the needed API surface
- **D-03:** Fall back to GDRETools decompilation of `Upload Labs.exe` as definitive source of truth
- **D-04:** Use **direct replacement** for old property names with new names (clean, readable)
- **D-05:** After confirmation, add **compatibility shims** (`has()`/`get()` checks) for graceful degradation
- **D-06:** Fix **both mods simultaneously** — STM and SGM share near-identical files
- **D-07:** Full edge cases required for "done":
  1. Resources redistribute to downstream windows after tick (baseline)
  2. All three modes produce observably different allocations: ratio, demand, graph
  3. Progress bar and % label update in real time
  4. Edge cases: 0 upstream, empty graph, single downstream window
- **D-08:** Both STM and SGM must pass all verification conditions
- **D-09:** Root cause is almost certainly `ResourceContainer` API changes between 2.1.8 and 2.1.10
- **D-10:** "Pulls half the resource on connect" is consistent with tick distributing to empty `state.wdata`

### Claude's Discretion
- How to structure the compatibility shim layer — property-by-property or wrapper class
- Whether to add `@warning_ignore` annotations or print statements during investigation
- Exact order of files to patch within each mod

### Deferred Ideas (OUT OF SCOPE)
- Merging STM and SGM into one mod
- Publishing back to Steam Workshop
- Support for game versions beyond 2.1.10
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FUNC-01 | STM redistributes `clock_speed` to connected downstream windows | ResourceContainer.tick() override mechanism verified; `transfer` array confirmed present and populated by `update_connections()` |
| FUNC-02 | SGM redistributes `gpu_speed` to connected downstream windows | SGM is structurally identical to STM; same API applies |
| FUNC-03 | Distribution modes (ratio, demand, graph) each produce correct behavior | `distribution_modes.gd` is pure math with no game API calls; logic confirmed intact |
| FUNC-04 | Progress bar and demand label update correctly | `window_smart_thread_manager.gd` process() reads `output.demand` which is the mod's own variable; confirmed correct |
| CODE-01 | Identify and fix all API mismatches using GDRETools decompilation | Decompilation completed — see findings below |
</phase_requirements>

---

## Summary

GDRETools decompilation of `Upload Labs.exe` (game version **2.1.11**, not 2.1.10 as expected) was completed and the full `ResourceContainer` class source is available. The critical finding: **every property and method name used by the mod exists in the current game API**. Specifically, `looping`, `transfer`, `id`, `production`, `required`, `type`, `containers`, `goal`, `count`, `outputs`, `input` all exist on `ResourceContainer` or `WindowBase` exactly as the mod uses them. No script errors appear in any game session log.

This overturns hypothesis D-09: the bug is **not** a property rename. All four session logs (`godot2026-04-16T12.29.55.log`, `12.31.41.log`, `12.37.30.log`, `12.42.18.log`) show zero `SCRIPT ERROR` entries for the mod code. The mods initialize cleanly and the window nodes load. The "distribution does nothing" symptom may have been caused by the version mismatch (manifest listed 2.1.5 / 2.1.8 but not 2.1.10) that Phase 1 already fixed.

**Primary recommendation:** First verify in-game with Phase 1 fixes active. If distribution still fails, instrument with print statements inside `tick()` to pinpoint the exact code path failure, since the API surface is intact.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tick-time resource distribution | `smart_resource_container.gd` (ResourceContainer subclass) | `distribution_modes.gd` (pure math) | Game calls `tick()` on every container in the window's `containers` array each tick |
| Window connection tracking | `stm_window_data.gd` (per-window state) | `window_graph.gd` (graph topology) | Each downstream window needs a `STMWindowData` object tracking its inputs |
| Mode/UI binding | `window_smart_thread_manager.gd` (WindowIndexed subclass) | — | Sets `distribution_mode` and `use_count` on the output container each frame |
| Graph topology | `stm_window_graph.gd` / `window_graph.gd` | `Signals` global | Graph mode requires tracking supplier/receiver relationships via `Signals.connection_created/deleted` |

---

## Standard Stack

### Core (verified from decompile)

| Item | Version | Purpose |
|------|---------|---------|
| GDScript 4 | Godot 4.5.1 (embedded) | Mod scripting language |
| `ResourceContainer` class | game 2.1.11 | Parent class for all mod container nodes |
| `WindowBase` / `WindowIndexed` | game 2.1.11 | Parent classes for window UI |
| `Utils` autoload | game 2.1.11 | `Utils.resource_types` enum (MATERIAL=0, FLOW=1, BOOST=2, MATERIAL_LIMITED=3, SETTING=4, HEAT=5, FLUID=6) |
| `Signals` autoload | game 2.1.11 | `tick`, `connection_created`, `connection_deleted`, `window_initialized`, `window_deleted` |
| GodotModLoader | — | Mod loading infrastructure |

---

## Architecture Patterns

### How tick() is called

```
Signals.tick (emitted by game engine each game tick)
  → WindowBase._on_tick()
    → WindowBase.process(Attributes.tick_speed)   ← mod's process() override runs here
    → WindowBase.tick_resources()
        → for i in containers: i.tick()           ← smart_resource_container.tick() runs here
```

The `containers` array on `WindowBase` contains ALL child nodes in the `"persistent_container"` group. The STM/SGM output node (which uses `smart_resource_container.gd`) IS in this group (via `output_container.tscn` which has `groups=["output", "persistent_container"]`). So `tick()` IS called.

### How transfer is populated

```
Signals.create_connection(output_id, input_id)
  → ResourceContainer._on_create_connection()
    → add_output(input_id)
      → outputs.append(container)
      → container.set_input(id)
      → container.closing.connect(...)
      → container.tick_set.connect(_on_output_paused)
      → update_connections()          ← populates transfer/looping

ResourceContainer.update_connections():
  transfer.clear(); looping.clear()
  for i in outputs:
    if !i.ticking or i.is_looping(self):
      looping.append(i)
    else:
      transfer.append(i)
```

The mod's override:
```gdscript
func update_connections() -> void:
    super()          # populates transfer and looping from base class
    data_changed = true   # flags _update_data() on next tick
```

### How ticking propagates to fill transfer correctly

On connection: downstream input container has `ticking=false` initially → goes to `looping`, not `transfer`.
When downstream window starts ticking: `set_ticking(true)` emits `tick_set` signal → connected to `_on_output_paused()` on the STM output → calls `update_connections()` again → downstream container now has `ticking=true` → moves to `transfer`.

This means after the first tick cycle following a connection, `transfer` will be correctly populated.

### data_changed lifecycle

```
_ready() → data_changed = true
update_connections() → data_changed = true
distribution_mode setter → data_changed = true

tick():
  if data_changed:
    _update_data()            # rebuilds state.wdata from transfer
    _update_callable(mode)    # sets distribution_callable
    data_changed = false
  for i in looping: i.count = 0
  _update_state_tick()        # computes state.demands
  distribution_callable.call(count, state)
  demand = state.get_or_add("demand", 0.0)
```

### STMWindowData: provided vs dependent

For a downstream window receiving `clock_speed` from STM:
- `inputs` = all `persistent_container` nodes in group `"input"` (file input, clock input, etc.)
- `provided` = inputs whose IDs are in `transfer` IDs (= the clock_speed input connected from STM)
- `dependent` = inputs NOT in provided AND are `MATERIAL` type (type=0) or `MATERIAL_LIMITED` (type=3)

`clock_speed` is type=1 (FLOW) → NOT captured by `_is_material()`. This is **intentional**: `provided` = the speed input being distributed, `dependent` = the material input the speed is applied to. `get_demand()` = `get_min_prod() * goal` = how fast the material flows × how many cycles needed.

For STM_MANAGER classification: `"demand" in window` checks if the window script has a `demand` property. The mod's own `window_smart_thread_manager.gd` adds `var demand` — so STM Manager windows ARE recognized as STM_MANAGER correctly.

---

## Confirmed API: ResourceContainer in 2.1.11

**Source: decompiled `/scenes/resource_container.gd`** [VERIFIED: GDRETools decompile of Upload Labs.exe]

```gdscript
class_name ResourceContainer extends Control

# Properties used by the mod — ALL CONFIRMED PRESENT
var id: String                          # unique container ID
var production: float                   # set(p): production = p; needs_update = true
var type: int                           # resource type index (0=MATERIAL, 1=FLOW, etc.)
var outputs: Array[ResourceContainer]   # downstream connected containers
var input: ResourceContainer            # upstream connected container
var transfer: Array[ResourceContainer]  # subset of outputs: currently ticking, non-looping
var looping: Array[ResourceContainer]   # subset of outputs: not ticking or is loop

@export var count: float                # set(c): count = c; needs_update = true
@export var required: float             # set(r): required = r; update_required()
@export var exporting: Array[ResourceContainer]

func update_connections() -> void:     # called on connect/disconnect; populates transfer/looping
func tick() -> void:                   # called by tick_resources() each game tick
func add(amount: float) -> void
func remove(amount: float) -> void
func set_count(amount: float) -> void
func pop(amount: float) -> float
func pop_all() -> float
```

**Properties NOT present in base ResourceContainer** (mod-added only):
- `demand` — this is declared in `window_smart_thread_manager.gd` as a getter that returns `output.demand`; `output` is a `smart_resource_container` which has its own `var demand: float`

---

## Confirmed API: WindowBase in 2.1.11

**Source: decompiled `/scenes/windows/window_base.gd`** [VERIFIED: GDRETools decompile]

```gdscript
class_name WindowBase extends WindowContainer

var containers: Array[ResourceContainer]  # all persistent_container group children
var paused: bool

func tick_resources() -> void:            # calls i.tick() on all containers
func should_tick() -> bool:               # returns !paused and !importing and !closing and !checking_pairs
func update_ticking() -> void:            # connects/disconnects Signals.tick
```

`goal` is NOT a property of `WindowBase` — it is a per-window-type property declared on individual window scripts (window_code.gd, window_crafter.gd, etc.). The check `"goal" in window` in `stm_window_data.gd` uses GDScript's dynamic property inspection, which works correctly.

`demand` is NOT a property of any base game window class — it is exclusively the mod's own addition via `window_smart_thread_manager.gd`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Game EXE source | Manual bytecode reading | GDRETools `--headless --recover` | Handles all Godot 4 bytecode versions automatically |
| Connection topology | Custom graph traversal | `stm_window_graph.gd` / `window_graph.gd` already exist | Graph code is complete and uses `Signals.connection_created/deleted` correctly |
| Demand calculation | Custom heuristics | `stm_window_data.get_demand()` already exists | Already accounts for manager/consumer/storage roles |

---

## Runtime State Inventory

Not applicable — this is a code fix phase, not a rename/migration phase. No stored data, service config, or OS-registered state is involved.

---

## Common Pitfalls

### Pitfall 1: Over-fixating on property renames that don't exist
**What goes wrong:** Spending time renaming `looping`→`X` or `transfer`→`Y` when those names are confirmed present in the decompiled source.
**Why it happens:** Hypothesis D-09 predicts a rename; decompile disproves it.
**How to avoid:** Trust the decompile. Every suspected renamed property was verified present.
**Warning signs:** If a "fix" changes property names without a script error confirming the old name is invalid, it's wrong.

### Pitfall 2: Assuming the bug is still present without testing
**What goes wrong:** Writing a "fix" for a bug that was already resolved by Phase 1's manifest update.
**Why it happens:** The mod was reported broken before Phase 1. Phase 1 fixed version compatibility. The bug may be gone.
**How to avoid:** ALWAYS run the game and test distribution behavior FIRST before touching code.
**Warning signs:** If distribution works after Phase 1, no code changes are needed in Phase 2.

### Pitfall 3: Misunderstanding the provided/dependent split
**What goes wrong:** Thinking `_is_material()` is a bug because clock_speed is FLOW type (type=1), not MATERIAL (type=0).
**Why it happens:** Looks wrong — the container being distributed IS the flow container.
**How to avoid:** Understand the design: `provided` = the speed inputs being fed from STM; `dependent` = the material inputs whose production rate determines how much speed is needed.
**Warning signs:** Never change `_is_material` to include FLOW types — that would break demand calculation.

### Pitfall 4: Timing of transfer population
**What goes wrong:** Observing `transfer` is empty at tick time and concluding the property is broken.
**Why it happens:** On first connection, downstream container has `ticking=false`, goes to `looping`. `transfer` only fills after one tick cycle when `_on_output_paused()` fires.
**How to avoid:** Add a print in `tick()` to check `transfer.size()` during second tick, not first.
**Warning signs:** `state.wdata.is_empty()` on the FIRST tick after connection is normal and expected.

### Pitfall 5: Wrong game version assumption
**What goes wrong:** Fixing for 2.1.10 while the game is actually 2.1.11.
**Why it happens:** Manifest was updated to 2.1.10; game auto-updated to 2.1.11.
**How to avoid:** Check `project.godot` config/version from decompile = "2.1.11". Add 2.1.11 to manifests if needed.
**Warning signs:** COMP-02 check finds unexpected version string in loader log.

---

## Code Examples

### Correct diagnostic instrumentation for tick() — add temporarily

```gdscript
# Source: smart_resource_container.gd — diagnostic additions
func tick() -> void:
    if data_changed:
        _update_data()
        _update_callable(distribution_mode)
        data_changed = false
    
    # DIAGNOSTIC: remove after fix confirmed
    if transfer.size() == 0:
        print("[STM] tick: transfer empty, looping=%d" % looping.size())
    if state.wdata.is_empty():
        print("[STM] tick: state.wdata empty")
    else:
        print("[STM] tick: wdata keys=%s, count=%f" % [state.wdata.keys(), count])
    
    for i: ResourceContainer in looping:
        i.count = 0
    _update_state_tick()
    distribution_callable.call(count, state)
    demand = state.get_or_add("demand", 0.0)
```

### Compatibility shim pattern (D-05) — after fix confirmed

```gdscript
# Pattern from window_smart_thread_manager.gd — use this for any uncertain properties
# Property-by-property shim using has()/get():
var value = node.get("property_name") if "property_name" in node else fallback_value
```

### How to update both mod manifests for game version 2.1.11

```json
"compatible_game_version": ["2.1.10", "2.1.11"]
```

Both mod manifests (`kuuk-SmartThreadManager/manifest.json` and `kuuk-SmartGPUManager/manifest.json`) must include both versions. COMP-02 may fail on 2.1.11 even though Phase 1 added 2.1.10.

---

## State of the Art

| Old Assumption | Actual Finding | Impact |
|----------------|----------------|--------|
| Game version is 2.1.10 | Game is 2.1.11 | Manifests may need 2.1.11 added |
| `looping` property renamed | `looping` confirmed present in 2.1.11 decompile | No rename fix needed |
| `transfer` property renamed | `transfer` confirmed present in 2.1.11 decompile | No rename fix needed |
| `container.id` may be renamed | `var id: String` confirmed in ResourceContainer | No rename fix needed |
| `container.production` may be renamed | `var production: float` confirmed | No rename fix needed |
| `container.required` may be renamed | `@export var required: float` confirmed | No rename fix needed |
| `container.type` may be renamed | `var type: int` confirmed | No rename fix needed |
| `window.containers` may be renamed | `var containers: Array[ResourceContainer]` confirmed in WindowBase | No rename fix needed |
| `window.demand` is a game property | `demand` is NOT in any base game class — it is the mod's own property | No change needed |
| `window.goal` is universal | `goal` exists on 37 window types, not WindowBase | `"goal" in window` dynamic check is correct as-is |
| Root cause is API rename (D-09) | NO API renames confirmed | Root cause is behavioral (unknown until in-game test) |

---

## Investigation Plan for Phase 2

Since the API is confirmed intact, Phase 2 must follow this order:

### Step 1: Manifest version check (30 minutes)
Verify the game is running 2.1.11 in the mod loader log. If manifests only list 2.1.10, COMP-02 will fail silently and the mod may not initialize. **Check before anything else.**

Indicator: `godot.log` line like `SUCCESS kuuk:STM:Main: Initialized, version: 2.1.11` — if this says 2.1.10 and the game is 2.1.11, the mod loaded anyway (compatible_game_version is a soft check), but update the manifests.

### Step 2: Baseline distribution test (30 minutes)
Set up: one STM → two downstream windows (e.g., two CPU windows with file input). Start resource flowing. Observe whether downstream windows receive proportional clock_speed.

Expected result if working: both CPUs receive approximately equal clock_speed.
Expected result if broken: one or both CPUs receives nothing, or receives the full amount.

### Step 3: If broken — add diagnostic prints to tick() (1 hour)
Add prints to `smart_resource_container.gd` as shown in Code Examples above. Repackage and retest. The print output will identify:
- If `transfer` is empty → connection signal pathway broken
- If `state.wdata` is empty → `_update_wdata` not being called or `transfer` is empty at call time
- If `state.wdata` has entries but `count=0` → `process()` not setting count, or wrong node referenced

### Step 4: Apply targeted fix
Based on diagnostic results. Most likely candidates:
1. **No fix needed** — distribution works after Phase 1 manifest fix (most likely)
2. **`state.wdata` empty** → check that `window.containers` on downstream windows includes input containers in `"input"` group; add `is_in_group("input")` print
3. **`transfer` always empty** → check `ticking` state on downstream containers; may need to delay `_update_data()` by one tick cycle
4. **demand = 0 for all windows** → check `provided.is_empty()` or role misclassification; add role print in `STMWindowData._init()`

### Step 5: All three modes + edge cases (D-07)
After baseline works: test ratio, demand, graph modes. Test edge cases from D-07.

### Step 6: Compatibility shims (D-05)
After fix confirmed: add `has()`/`get()` shims to any properties accessed on game objects, following the pattern in `window_smart_thread_manager.gd`.

---

## Environment Availability

| Dependency | Available | Version | Notes |
|------------|-----------|---------|-------|
| GDRETools | ✓ | 2.4.0 (winget) | Installed at `C:/Users/Jake/AppData/Local/Microsoft/WinGet/Packages/GDRETools.gdsdecomp_.../gdre_tools.exe` |
| Upload Labs.exe | ✓ | 2.1.11 | `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/Upload Labs.exe` |
| Decompiled source | ✓ | 2.1.11 | At `/tmp/gdre_decompile/` (session temp; re-run command to regenerate) |
| Game logs | ✓ | — | `C:/Users/Jake/AppData/Roaming/Upload Labs/logs/godot.log` |

**GDRETools decompile command (for re-use):**
```bash
"C:/Users/Jake/AppData/Local/Microsoft/WinGet/Packages/GDRETools.gdsdecomp_Microsoft.Winget.Source_8wekyb3d8bbwe/gdre_tools.exe" \
  --headless \
  --recover="D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/Upload Labs.exe" \
  --output-dir=/tmp/gdre_decompile
```

---

## Validation Architecture

> (nyquist_validation not confirmed enabled/disabled; no config.json found — treating as enabled)

No automated test framework is applicable here — this is in-game behavior verification only. All tests are manual human checkpoints.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FUNC-01 | STM distributes clock_speed downstream | manual | n/a — requires game launch | — |
| FUNC-02 | SGM distributes gpu_speed downstream | manual | n/a — requires game launch | — |
| FUNC-03 | All three modes produce different allocations | manual | n/a | — |
| FUNC-04 | Progress bar + demand label update | manual | n/a | — |
| CODE-01 | No API mismatches with 2.1.11 | verified | n/a — decompile complete | — |

**All tests are manual-only.** There is no test infrastructure for this project. Verification requires launching the game, placing windows, making connections, and observing behavior.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The "distribution logic does nothing" symptom was caused by the manifest version mismatch fixed in Phase 1, not by any code-level API break | Summary | If wrong: need to add print diagnostics and investigate the behavioral code path — see Investigation Plan Steps 2-4 |
| A2 | The game has not changed the `ResourceContainer` API between the decompile date (2026-04-16) and the next test run | Standard Stack | Negligible risk — game would have to update again |
| A3 | `clock_speed` type=1 (FLOW) is the correct and intended type for STM distribution (the `_is_material` design is correct) | Architecture Patterns | If wrong: all clock_speed consumer windows would have demand=0; test with Demand mode to verify demand values are non-zero |

**If A1 is wrong:** The investigation plan in this document provides the full diagnostic path.

---

## Open Questions (RESOLVED)

1. **Is distribution actually broken after Phase 1?**
   - What we know: manifests now list 2.1.10; game is 2.1.11; no script errors in logs
   - What's unclear: no in-game test has been run since Phase 1 install
   - Recommendation: Test first. Only proceed to code changes if test fails.
   - **RESOLVED:** Addressed by Plan 02-01 Task 2 checkpoint -- the baseline test will answer this. Result recorded in 02-01-SUMMARY.md.

2. **Does the game's 2.1.11 version require manifest update?**
   - What we know: `project.godot` config/version = "2.1.11"; manifests were updated to include "2.1.10"
   - What's unclear: whether the mod loader's version check is exact-match or prefix-match
   - Recommendation: Check the mod loader log after game launch. If it shows a version warning for kuuk mods, add "2.1.11" to compatible_game_version.
   - **RESOLVED:** YES -- addressed by Plan 02-01 Task 1 which adds "2.1.11" to compatible_game_version in both manifests.

3. **Will `state.wdata` populate correctly for windows that only have clock_speed inputs (no material-type inputs)?**
   - What we know: `dependent` is empty for pure-clock_speed windows; `provided` will have the clock_speed container
   - What's unclear: whether such windows would be classified as STM_STORAGE and correctly receive any overflow
   - Recommendation: Test with windows that have both clock_speed + material inputs first (CPU-type windows); these are the primary use case.
   - **RESOLVED:** RESEARCH found clock_speed is type=FLOW (provided), material containers are type=0 (dependent). Demand calculation uses dependent containers only. Clock_speed-only windows will have empty `stm_window_data.wdata` but that is correct behavior -- test with CPU-type (demand) windows to verify mode switching.

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: GDRETools decompile of Upload Labs.exe 2.1.11] — `/tmp/gdre_decompile/scenes/resource_container.gd` — full ResourceContainer source
- [VERIFIED: GDRETools decompile] — `/tmp/gdre_decompile/scenes/windows/window_base.gd` — WindowBase source
- [VERIFIED: GDRETools decompile] — `/tmp/gdre_decompile/scripts/signals.gd` — all Signals confirmed present
- [VERIFIED: GDRETools decompile] — `/tmp/gdre_decompile/scripts/utils.gd` — resource_types enum confirmed
- [VERIFIED: GDRETools decompile] — `/tmp/gdre_decompile/data/resources.json` — clock_speed type=1 (FLOW), gpu_speed type=1 (FLOW)
- [VERIFIED: game log] — `C:/Users/Jake/AppData/Roaming/Upload Labs/logs/godot.log` — no script errors from mod code
- [VERIFIED: codebase grep] — all 4 target files read in full; STM and SGM are near-identical (only preload paths and one type annotation differ)

### Secondary (MEDIUM confidence)
- [VERIFIED: workshop mod source] — `Bottlenecks/mod_main.gd` — confirms `container.production`, `container.count`, `container.required` API still in use by other working mods
- [VERIFIED: workshop mod source] — `BetterSplitters/base_splitter.gd` — confirms `input.count`, `output.count`, `output.outputs` still work; `connection_out_set` signal exists

---

## Metadata

**Confidence breakdown:**
- API names: HIGH — verified by decompile of live game EXE
- Root cause: MEDIUM — D-09 hypothesis disproved; actual root cause unknown until in-game test
- Fix strategy: HIGH — investigation plan is correct regardless of which code path fails
- Architecture patterns: HIGH — verified by reading all 7 mod script files + decompiled WindowBase/ResourceContainer

**Research date:** 2026-04-16
**Valid until:** ~2026-05-16 (stable game; low risk of update breaking research)

**GDRETools install location:** `C:/Users/Jake/AppData/Local/Microsoft/WinGet/Packages/GDRETools.gdsdecomp_Microsoft.Winget.Source_8wekyb3d8bbwe/gdre_tools.exe`
**Decompiled source location:** `/tmp/gdre_decompile/` (Windows temp — regenerate if session restarted)
