# Phase 2: Verify & Debug - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the API mismatches between what both kuuk mods call and what Upload Labs 2.1.10's `ResourceContainer` currently exposes, then verify all three distribution modes work correctly in-game.

This phase does NOT include: merging the two mods, new distribution modes, UI redesign, or publishing to Steam Workshop.

</domain>

<decisions>
## Implementation Decisions

### API Discovery Order
- **D-01:** Try examining working Workshop mods first (Bottlenecks, BetterSplitters already in the Steam directory) to see how they use ResourceContainer. Quick and may give us the renamed property names immediately.
- **D-02:** If workshop mods don't use the same API surface (e.g., they don't touch `looping`/`transfer`/`id`), check the Godot Modding wiki (wiki.godotmodding.com) for ResourceContainer documentation or changelogs.
- **D-03:** If documentation is insufficient, fall back to decompiling the current game EXE with GDRETools (CLAUDE.md documents the exact procedure). This is the definitive source of truth.

### Fix Strategy
- **D-04:** Use **direct replacement** — replace old property names (`looping`, `transfer`, `id`, etc.) with new names throughout the scripts. Clean and readable.
- **D-05:** After the mod is confirmed working, add **compatibility shims** (`has()`/`get()` checks like the window script already uses) so the mod degrades gracefully if the game updates again instead of breaking silently.
- **D-06:** Fix **both mods simultaneously** — STM and SGM share near-identical script files, so every change applies to both at once. Do not fix one and then the other.

### Verification Scope
- **D-07:** Full edge cases required for done:
  1. Resources redistribute to downstream windows after tick (baseline)
  2. All three modes produce observably different allocations: ratio, demand, graph
  3. Progress bar and % label update in real time
  4. Edge cases: 0 upstream resource (mods should distribute 0 cleanly), empty graph (graph mode with no graph connections), single downstream window (ratio/demand with only one consumer)
- **D-08:** Both STM and SGM must pass all verification conditions — not just one mod.

### Known Root Cause Hypothesis
- **D-09:** The mod source code is **identical** to the working reference (ul-stmmod-2.1.5). The bug is almost certainly in `ResourceContainer` API changes between 2.1.8 and 2.1.10 — specifically the properties `looping` and `transfer` (used in `smart_resource_container.gd` lines 60 and 99), and possibly `id`, `production`, `required`, `type` on individual containers, or `window.containers`, `window.demand`, `window.goal` on `WindowBase`.
- **D-10:** The symptom "pulls half the resource on connect" is consistent with `tick()` distributing to an empty `state.wdata` (because `transfer` is empty/renamed), leaving the game's base `ResourceContainer` passthrough behavior in effect.

### Claude's Discretion
- How exactly to structure the compatibility shim layer (added in D-05) — property-by-property or a single compatibility wrapper class.
- Whether to add GDScript `@warning_ignore` annotations or print statements for debugging during the investigation phase.
- Exact order of files to patch within each mod (start with `smart_resource_container.gd` since it's the most likely culprit, then `stm_window_data.gd` if needed).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Mod source (both mods — fix simultaneously)
- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/smart_resource_container.gd` — Primary fix target: uses `looping` (line 60) and `transfer` (line 99)
- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/global/stm_window_data.gd` — Uses `window.containers`, `container.id`, `window.demand`, `window.goal`, `container.production`, `container.required`, `container.type`
- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scripts/global/distribution_modes.gd` — Pure math, unlikely broken but must be checked
- `Smrt Thread Manager/mods-unpacked/kuuk-SmartThreadManager/scenes/windows/window_smart_thread_manager.gd` — Window UI; already uses defensive `has()` checks
- `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/smart_resource_container.gd` — Same file as STM version; fix simultaneously
- `Smrt GPU Manager/mods-unpacked/kuuk-SmartGPUManager/scripts/global/stm_window_data.gd` — Same file as STM version; fix simultaneously

### Reference source (working implementation for 2.1.5)
- `ul-stmmod-2.1.5/scripts/smart_resource_container.gd` — Currently identical to broken versions; proves the logic is correct, the API is what changed

### API investigation targets (Workshop mods already on disk)
- `D:/Program Files (x86)/Steam/steamapps/workshop/content/3606890/3651033564/` — Bottlenecks mod (examine source if accessible)
- `D:/Program Files (x86)/Steam/steamapps/workshop/content/3606890/3656227077/` — BetterSplitters mod
- `D:/Program Files (x86)/Steam/steamapps/workshop/content/3606890/3656872243/` — ModList mod
- `D:/Program Files (x86)/Steam/steamapps/workshop/content/3606890/3664093132/` — OfflineEarnings mod

### Documentation
- `https://wiki.godotmodding.com` — Godot Modding wiki; check for ResourceContainer API docs or Upload Labs-specific modding guides
- `CLAUDE.md` §"Recommended Tool" — GDRETools decompilation procedure (fallback if workshop mods + wiki insufficient)
- `D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/Upload Labs.exe` — Game executable for GDRETools decompilation (last resort)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `stm_window_data.gd` already handles role classification (consumer/manager/storage/artifact) — this logic should survive unchanged
- `distribution_modes.gd` is pure math with no game API calls — very unlikely to need changes
- `window_smart_thread_manager.gd` already uses defensive `if "property" in node` checks — this pattern should be extended to `smart_resource_container.gd` in D-05

### Established Patterns
- The window script uses `if "distribution_mode" in output: output.get("distribution_mode")` — this is the compatibility pattern to follow when adding shims in D-05
- Both STM and SGM are near-identical codebases; every fix applies to both simultaneously (D-06)

### Integration Points
- `smart_resource_container.gd` connects to the game via `ResourceContainer` (parent class) — its `looping`, `transfer`, `count`, and `tick()` are the integration boundary
- `stm_window_data.gd` connects to the game via `WindowBase` (`window.containers`) and `ResourceContainer` individual instances (`container.id`, `.type`, `.production`, `.required`)
- The game calls `tick()` on containers — if this calling convention changed, `smart_resource_container.tick()` may not be invoked at all

</code_context>

<specifics>
## Specific Ideas

- Fix both mods at the same time, not sequentially — they are near-identical and sequential fixing would require two rounds of in-game testing
- The "Base: count/s" label visible in the screenshot is likely the base window's default display, not the mod's custom UI — this may or may not need fixing depending on whether it's a separate issue
- After the direct fix works, the compatibility shim pass (D-05) should use the same `has()`/`get()` pattern already in `window_smart_thread_manager.gd`

</specifics>

<deferred>
## Deferred Ideas

- Merging STM and SGM into a single mod (noted in mod source: "One day i will merge this") — out of scope for this fix
- Publishing back to Steam Workshop — user's choice post-fix
- Support for game versions beyond 2.1.10

</deferred>

---

*Phase: 02-verify-debug*
*Context gathered: 2026-04-16*
