# Phase 1: Package & Install - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 01 - Package & Install
**Areas discussed:** Install format, Manifest changes scope, Phase 1 done condition

---

## Install Format

| Option | Description | Selected |
|--------|-------------|----------|
| Copy raw folders | Copy `kuuk-SmartThreadManager/` and `kuuk-SmartGPUManager/` directly into game's `mods-unpacked/`. Fastest, easiest to iterate. | ✓ |
| Zip first | Package each mod into a `.zip`, drop in `mods-unpacked/`. Matches Workshop format but adds packaging step. | |
| Symlinks / junctions | Directory junction from game's `mods-unpacked/` to source folder. Changes reflected instantly. | |

**User's choice:** Copy raw folders
**Notes:** None.

---

## Manifest Changes Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal | Add only `"2.1.10"` to `compatible_game_version`. Touch nothing else. | |
| Practical | Add `"2.1.10"` + check/update `compatible_mod_loader_version` if newer GML ships with 2.1.10. Keep old versions, don't touch `version_number`. | |
| Clean slate | Add `"2.1.10"`, update mod loader version if needed, bump `version_number`, trim old game version list to tested versions only. | ✓ |

**User's choice:** Clean slate
**Notes:** `version_number` set to `"2.1.10"`. Trim `compatible_game_version` to `["2.1.8", "2.1.10"]`.

---

## Phase 1 Done Condition

| Option | Description | Selected |
|--------|-------------|----------|
| Files in place | Done when mod folders are copied and manifests updated. No game launch required. | |
| Log check | Game launch + GodotModLoader log shows both mods loaded without errors. | |
| Full success criteria | Game launch + clean log + both windows appear + both accept connections. Strictest gate. | ✓ |

**User's choice:** Full success criteria — all four roadmap criteria must pass before moving to Phase 2.
**Notes:** None.

---

## Claude's Discretion

- How to detect GodotModLoader version bundled with the 2.1.10 game
- Exact ordering/whitespace in trimmed `compatible_game_version` array

## Deferred Ideas

None.
