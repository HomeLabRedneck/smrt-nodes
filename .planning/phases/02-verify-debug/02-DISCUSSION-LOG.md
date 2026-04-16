# Phase 2: Verify & Debug - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 02-verify-debug
**Areas discussed:** API Discovery, Fix Style, Verification Scope

---

## API Discovery

| Option | Description | Selected |
|--------|-------------|----------|
| Decompile game EXE | GDRETools on Upload Labs.exe — definitive, exact property names | |
| Examine workshop mods | Look at Bottlenecks/BetterSplitters already on disk | ✓ (first) |
| Both in parallel | Decompile + workshop scan simultaneously | |

**User's choice:** Try workshop mods first. If they don't use the right API surface, check the Godot Modding wiki. Decompile as last resort.

**Notes:** User referenced "the Wiki I posted earlier" — confirmed to be wiki.godotmodding.com.

---

## Fix Style

| Option | Description | Selected |
|--------|-------------|----------|
| Direct replacement | Replace old property names with new ones — clean, readable | ✓ (first) |
| Compatibility shims | has()/get() checks, graceful degradation across game versions | ✓ (after working) |

**User's choice:** Direct replacement first to get it working, then add compatibility shims afterward.

**Notes:** Two-phase approach — correctness first, resilience second.

---

## Verification Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Basic redistribution | Confirm resources move after tick | |
| All 3 modes + progress bar | Match Phase 2 success criteria exactly | |
| Full edge cases | All 3 modes + 0 upstream, empty graph, single consumer | ✓ |

**User's choice:** Full edge cases — all three modes working plus edge conditions.

---

## Fix Both Mods Simultaneously

**User's choice:** Fix STM and SGM at the same time — same scripts, same changes.

---

## Claude's Discretion

- Compatibility shim structure (after direct fix confirmed working)
- Whether to add debug print statements during investigation
- Order of files to patch within each mod

## Deferred Ideas

- Merge STM and SGM into one mod
- Steam Workshop publishing
- Support for game versions beyond 2.1.10
