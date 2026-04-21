# Decompilation Approach

**Project:** Upload Labs (Godot 4, Steam, Windows)
**Researched:** 2026-04-16
**Confidence:** HIGH — primary tool is well-documented, actively maintained, and widely used

---

## Recommended Tool

**GDRETools / gdsdecomp**

- GitHub: https://github.com/GDRETools/gdsdecomp
- Latest stable: **v0.9.1** (Windows: `GDRE_tools-v0.9.1-windows.zip`)
- Latest beta: **v2.5.0-beta.5** (released April 7, 2026)
- Releases page: https://github.com/GDRETools/gdsdecomp/releases
- WinGet ID: `GDRETools.gdsdecomp`

**Recommendation:** Use v0.9.1 stable for reliability. The v2.x beta series exists but the winget-published stable is v0.9.1. Either will handle Godot 4 embedded EXEs — check the releases page at time of use for the current stable.

**Why this tool over alternatives:**

- GodotPCKExplorer (https://github.com/DmitriySalnikov/GodotPCKExplorer) can split EXE+PCK but does NOT decompile GDScript bytecode to source. It is a file extractor only.
- GdTool (https://github.com/lucasbaizer/GdTool) is an older CLI alternative with a GDScript decompiler, but GDRETools is more actively maintained and has broader Godot 4 support.
- godotdec (https://github.com/Bioruebe/godotdec) is an unpacker only — no decompilation.

---

## Workflow

### Step 1 — Download GDRETools

Download `GDRE_tools-vX.X.X-windows.zip` from https://github.com/GDRETools/gdsdecomp/releases and extract it. The archive contains `gdre_tools.exe`.

### Step 2 — Full Project Recovery (GUI, simplest path)

1. Launch `gdre_tools.exe`.
2. Drag and drop `"D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/Upload Labs.exe"` onto the GDRE window.
   - Alternatively: menu bar → **RE Tools** → **Recover Project...** → navigate to the EXE.
3. GDRE automatically detects the embedded PCK inside the EXE — no manual extraction step needed.
4. It reads the PCK header, detects the Godot engine version and GDScript bytecode version automatically. The recovery log will display the detected version (e.g. `Godot 4.x.x`).
5. Choose an output directory when prompted. Use something like `D:/Upload_Labs_decompiled/`.
6. Ensure "Full recovery" is selected (not just "Extract files"). This triggers GDScript decompilation.
7. Wait for completion. The log will show each file recovered, including decompiled `.gd` scripts.

### Step 2 (alternative) — CLI / Headless

```
gdre_tools.exe --headless --recover="D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/Upload Labs.exe" --output="D:/Upload_Labs_decompiled"
```

For extraction only (raw binary files, no decompilation):
```
gdre_tools.exe --headless --extract="D:/Program Files (x86)/Steam/steamapps/common/Upload Labs/Upload Labs.exe" --output="D:/Upload_Labs_extracted"
```

### Step 3 — Locate Target Scripts

After recovery completes, the output directory mirrors the original `res://` project structure. Navigate to:

```
D:/Upload_Labs_decompiled/
  project.godot
  addons/
  scenes/
  scripts/
      ...
```

The exact subdirectory depends on how the Upload Labs developers organized their project. Search recursively for the target filenames (see Expected Output below).

### Step 4 — Diff Between Versions

Run the decompilation twice — once against the v2.1.8 EXE and once against the v2.1.10 EXE — into separate output directories. Then diff the relevant `.gd` files:

```
# Windows (PowerShell / any diff tool)
diff "D:/Upload_Labs_v218_decompiled/scripts/resource_container.gd" \
     "D:/Upload_Labs_v210_decompiled/scripts/resource_container.gd"
```

Or use VS Code's built-in diff: open both files, right-click one → "Select for Compare", then right-click the other → "Compare with Selected".

---

## Expected Output

After full recovery, all GDScript files are written as human-readable `.gd` text files, preserving the original `res://` path structure.

### Target files to locate

Search the output directory for these filenames (case-insensitive, the exact paths depend on the game's internal project structure):

| Class | Expected filename | Likely subdirectory |
|-------|------------------|---------------------|
| `ResourceContainer` | `resource_container.gd` | `scripts/` or `ui/` or `core/` |
| `WindowBase` | `window_base.gd` | `scripts/ui/` or `windows/` |
| `WindowIndexed` | `window_indexed.gd` | `scripts/ui/` or `windows/` |

Since `WindowIndexed` extends `WindowBase` which presumably extends some base, and `ResourceContainer` is described as a base class, expect these to be in a shared/core scripts directory rather than a scene-specific one.

**PowerShell search after decompile:**
```powershell
Get-ChildItem -Path "D:\Upload_Labs_decompiled" -Recurse -Filter "*resource_container*"
Get-ChildItem -Path "D:\Upload_Labs_decompiled" -Recurse -Filter "*window_base*"
Get-ChildItem -Path "D:\Upload_Labs_decompiled" -Recurse -Filter "*window_indexed*"
```

**What the decompiled GDScript will look like:**

GDScript bytecode decompilation is high-fidelity. You will get back:
- All function definitions with original names (function names are stored as strings in bytecode)
- All variable names (also stored as strings)
- Class hierarchy (`extends` declarations)
- Signal definitions
- Export annotations (`@export`, `@onready`)
- Logic structure (if/else, loops, match) — reconstructed from bytecode opcodes

The only things that may be lossy: comments (stripped at compile time) and some formatting/whitespace.

---

## Gotchas

### 1. Bytecode version must match — but GDRE handles this automatically

Godot 4 compiles GDScript to a bytecode format versioned by engine release. GDRE reads the bytecode version from the PCK header and selects the correct decompiler. If GDRE does not recognize the bytecode version (e.g., a very new Godot 4.x release that predates the GDRE version you downloaded), decompilation of scripts will fail or produce garbage. Mitigation: use the latest GDRE release.

You can also force the version manually:
```
gdre_tools.exe --headless --recover=... --force-bytecode-version=4.3.0
```

List all supported bytecode versions your GDRE build knows about:
```
gdre_tools.exe --headless --list-bytecode-versions
```

### 2. No separate PCK file needed

The Upload Labs EXE has the PCK embedded — GDRE handles this natively. Do NOT try to manually split the EXE first; just feed the EXE directly to GDRE.

### 3. Encryption — unlikely for this game, but possible

If Upload Labs used PCK encryption, GDRE will report the PCK is encrypted and refuse to proceed without a key. To check: run GDRE on the EXE; if it fails with an encryption error, the key must be extracted from the binary using a separate tool (`gdke` or similar). For most indie Steam games this is not used. Given that Upload Labs is a small-to-mid indie title, encryption is unlikely.

### 4. GDScript obfuscation — very unlikely

The GDMaim plugin (https://github.com/cherriesandmochi/gdmaim) can obfuscate GDScript variable and function names before export. If used, decompiled output will show names like `_0x3fa2b` instead of `resource_container`. This is rare. If you see mangled identifiers, check for a `gdmaim` or obfuscation-related config in the decompiled project root.

### 5. GDExtension / C++ code is NOT decompiled

If any functionality is in a `.gdextension` (native C++ extension), GDRE will extract the `.dll` file but cannot decompile it to readable source. The GDScript layer will still be recovered. For Upload Labs this is unlikely to affect `ResourceContainer` — base classes shared across UI windows are almost always pure GDScript.

### 6. You need to run decompilation on the specific version EXE

Steam by default keeps only the current version. To get v2.1.8 specifically, you need to use Steam's "download depot" feature or have a backup of the old EXE. The depot manifest approach: SteamDB → Upload Labs → Depots → find the build ID for version 2.1.8 → use `download_depot` in Steam console. This is outside the scope of GDRE but is a prerequisite for comparing the two versions.

### 7. Output directory must be writable

Avoid outputting into `Program Files` — use a path like `D:\Upload_Labs_decompiled\` that does not require elevation.

---

## Sources

- GDRETools/gdsdecomp GitHub: https://github.com/GDRETools/gdsdecomp
- GDRETools releases: https://github.com/GDRETools/gdsdecomp/releases
- Godot Mod Loader decompile guide: https://wiki.godotmodding.com/guides/modding/tools/decompile_games/
- GodotPCKExplorer (extract-only alternative): https://github.com/DmitriySalnikov/GodotPCKExplorer
- GDMaim obfuscation plugin: https://github.com/cherriesandmochi/gdmaim
- WinGet package info: https://winget.ragerworks.com/package/GDRETools.gdsdecomp
