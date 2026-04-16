<!-- GSD:project-start source:PROJECT.md -->
## Project

**Upload Labs Smrt Nodes — Mod Fix**

Fix two broken Upload Labs mods — **SmartThreadManager** and **SmartGPUManager** — so they work with game version 2.1.10. Both mods were authored by `kuuk` and published on Steam Workshop. They provide "smart" auto-distribution of CPU thread speed and GPU speed respectively, letting players set up automatic load-balancing across connected windows.

**Core value:** Both mods load, render, and accept connections in 2.1.10 — but the distribution logic does nothing. The fix restores the actual smart-allocation behavior.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Tool
- GitHub: https://github.com/GDRETools/gdsdecomp
- Latest stable: **v0.9.1** (Windows: `GDRE_tools-v0.9.1-windows.zip`)
- Latest beta: **v2.5.0-beta.5** (released April 7, 2026)
- Releases page: https://github.com/GDRETools/gdsdecomp/releases
- WinGet ID: `GDRETools.gdsdecomp`
- GodotPCKExplorer (https://github.com/DmitriySalnikov/GodotPCKExplorer) can split EXE+PCK but does NOT decompile GDScript bytecode to source. It is a file extractor only.
- GdTool (https://github.com/lucasbaizer/GdTool) is an older CLI alternative with a GDScript decompiler, but GDRETools is more actively maintained and has broader Godot 4 support.
- godotdec (https://github.com/Bioruebe/godotdec) is an unpacker only — no decompilation.
## Workflow
### Step 1 — Download GDRETools
### Step 2 — Full Project Recovery (GUI, simplest path)
### Step 2 (alternative) — CLI / Headless
### Step 3 — Locate Target Scripts
### Step 4 — Diff Between Versions
# Windows (PowerShell / any diff tool)
## Expected Output
### Target files to locate
| Class | Expected filename | Likely subdirectory |
|-------|------------------|---------------------|
| `ResourceContainer` | `resource_container.gd` | `scripts/` or `ui/` or `core/` |
| `WindowBase` | `window_base.gd` | `scripts/ui/` or `windows/` |
| `WindowIndexed` | `window_indexed.gd` | `scripts/ui/` or `windows/` |
- All function definitions with original names (function names are stored as strings in bytecode)
- All variable names (also stored as strings)
- Class hierarchy (`extends` declarations)
- Signal definitions
- Export annotations (`@export`, `@onready`)
- Logic structure (if/else, loops, match) — reconstructed from bytecode opcodes
## Gotchas
### 1. Bytecode version must match — but GDRE handles this automatically
### 2. No separate PCK file needed
### 3. Encryption — unlikely for this game, but possible
### 4. GDScript obfuscation — very unlikely
### 5. GDExtension / C++ code is NOT decompiled
### 6. You need to run decompilation on the specific version EXE
### 7. Output directory must be writable
## Sources
- GDRETools/gdsdecomp GitHub: https://github.com/GDRETools/gdsdecomp
- GDRETools releases: https://github.com/GDRETools/gdsdecomp/releases
- Godot Mod Loader decompile guide: https://wiki.godotmodding.com/guides/modding/tools/decompile_games/
- GodotPCKExplorer (extract-only alternative): https://github.com/DmitriySalnikov/GodotPCKExplorer
- GDMaim obfuscation plugin: https://github.com/cherriesandmochi/gdmaim
- WinGet package info: https://winget.ragerworks.com/package/GDRETools.gdsdecomp
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
