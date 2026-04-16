# Requirements

## v1 Requirements

### Installation
- [ ] **INST-01**: Package SmartThreadManager source into a loadable mod zip/folder
- [ ] **INST-02**: Package SmartGPUManager source into a loadable mod zip/folder
- [ ] **INST-03**: Install both mods into the game's local mods directory so they load without Steam Workshop

### Compatibility
- [x] **COMP-01**: Update both manifests to include `"2.1.10"` in `compatible_game_version`
- [ ] **COMP-02**: Both mods must initialize without errors in the mod loader log

### Functionality
- [ ] **FUNC-01**: SmartThreadManager correctly redistributes clock_speed to connected downstream windows based on the selected mode (ratio/demand/graph)
- [ ] **FUNC-02**: SmartGPUManager correctly redistributes gpu_speed to connected downstream windows
- [ ] **FUNC-03**: Distribution modes (ratio, demand, graph) each produce correct behavior
- [ ] **FUNC-04**: Progress bar and demand label in the window UI update correctly

### Code Integrity
- [ ] **CODE-01**: If any game API changed since Feb 2026 (game updated past 2.1.10), identify and fix all mismatches using GDRETools decompilation
- [x] **CODE-02**: `smart_resource_container.gd` uses `extends ResourceContainer` (already correct in v2.1.5)

## v2 Requirements (Deferred)
- Merge SmartThreadManager and SmartGPUManager into one mod
- Support for game versions beyond 2.1.10

## Out of Scope
- New distribution modes beyond ratio/demand/graph
- UI redesign
- Publishing back to Steam Workshop (user's choice)

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INST-01 | Phase 1 | Pending |
| INST-02 | Phase 1 | Pending |
| INST-03 | Phase 1 | Pending |
| COMP-01 | Phase 1 | Complete |
| COMP-02 | Phase 1 | Pending |
| CODE-02 | Phase 1 | Complete |
| FUNC-01 | Phase 2 | Pending |
| FUNC-02 | Phase 2 | Pending |
| FUNC-03 | Phase 2 | Pending |
| FUNC-04 | Phase 2 | Pending |
| CODE-01 | Phase 2 | Pending |
