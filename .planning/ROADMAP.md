# Roadmap — Upload Labs Smrt Nodes Mod Fix

## Phases

- [ ] **Phase 1: Package & Install** - Package both mods, fix manifests, install locally so the game loads them
- [ ] **Phase 2: Verify & Debug** - Confirm distribution logic works in-game; fix any remaining API mismatches

---

## Phase Details

### Phase 1: Package & Install
**Goal**: Both mods are installed locally and recognized by GodotModLoader without Steam Workshop
**Depends on**: Nothing
**Requirements**: INST-01, INST-02, INST-03, COMP-01, COMP-02, CODE-02
**Success Criteria** (what must be TRUE):
  1. Both mod folders exist under the game's local mods directory and are found by the loader on startup
  2. Both manifests list `"2.1.10"` in `compatible_game_version`
  3. The mod loader log shows no initialization errors for either mod
  4. Both mod windows appear in-game and accept connections
**Plans:** 1/3 plans executed
Plans:
- [x] 01-01-PLAN.md — Update both manifests to 2.1.10 (COMP-01) and verify CODE-02 in both source trees
- [ ] 01-02-PLAN.md — Package both mods as ZIPs (INST-01, INST-02) and install into game_dir/mods/ (INST-03, overrides D-01 per RESEARCH)
- [ ] 01-03-PLAN.md — Launch game, verify COMP-02 via modloader.log, human checkpoint for D-06 conditions 3+4

### Phase 2: Verify & Debug
**Goal**: Both mods correctly redistribute resources to downstream windows using all three distribution modes
**Depends on**: Phase 1
**Requirements**: FUNC-01, FUNC-02, FUNC-03, FUNC-04, CODE-01
**Success Criteria** (what must be TRUE):
  1. SmartThreadManager redistributes `clock_speed` to connected windows — downstream values change when the manager ticks
  2. SmartGPUManager redistributes `gpu_speed` to connected windows — downstream values change when the manager ticks
  3. Switching distribution modes (ratio, demand, graph) produces observably different allocation across windows
  4. Progress bar and demand label in each window UI update in real time
**Plans**: TBD

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Package & Install | 1/3 | In Progress|  |
| 2. Verify & Debug | 0/0 | Not started | - |
