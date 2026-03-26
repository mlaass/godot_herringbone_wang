# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.6 addon implementing a herringbone Wang tile generator. The addon lives in `addons/herringbone_wang_generator/`. Uses GL Compatibility renderer with Jolt Physics 3D.

See `docs/initial_prd_herringbone_wang.md` for the product requirements.

## Running

Open in Godot 4.6+. GDScript runs directly from the Godot editor; the native extension requires a one-time build.

```bash
godot46                    # Open editor
godot46 --headless --quit  # Validate project parses
```

## Building the GDExtension

Requires [godot-cpp](https://github.com/godotengine/godot-cpp) built at `~/workspace/godot-cpp` and SCons.

```bash
# Build native extension
cd addons/herringbone_wang_generator/native_src && scons platform=linux target=release

# Cross-compile for Windows (from Linux)
cd addons/herringbone_wang_generator/native_src && scons platform=windows target=release

# Verify extension loads
godot46 --headless --quit 2>&1 | grep -i "error"
```

Output binaries go to `addons/herringbone_wang_generator/`.

## Testing

### Headless validation
After any GDScript or shader change, run headless validation:
```bash
timeout 10 godot46 --headless --path . 2>&1
```
Check for `SCRIPT ERROR`, `Parse Error`, and `Failed to load` in the output.

### GUT tests
The project uses [GUT](https://github.com/bitwes/Gut) v9.6.0 for unit and integration tests. Tests live in `test/` with `unit/`, `integration/`, and `smoke/` subdirectories.

```bash
# Run all GUT tests headless
godot46 -s addons/gut/gut_cmdln.gd --headless

# Run specific test file
godot46 -s addons/gut/gut_cmdln.gd --headless -gtest=res://test/unit/test_macro_data.gd

# Run tests matching a pattern
godot46 -s addons/gut/gut_cmdln.gd --headless -gselect=herringbone
```

All test files use `test_` prefix, extend `GutTest`, and follow the same code conventions as production code.

## Project Structure

```
addons/herringbone_wang_generator/   # The addon (self-contained, installable)
  native_src/                        # C++ GDExtension source
    thirdparty/                      # Vendored stb_herringbone_wang_tile.h
    src/                             # C++ wrapper code
    SConstruct                       # SCons build config
  herringbone_native.gdextension     # Extension manifest
  lib*.so / *.dll                    # Compiled native libraries
docs/                                # Design documents, PRDs, and references
test/                                # GUT tests
  unit/                              # Unit tests
  integration/                       # Integration tests
  smoke/                             # Smoke/load tests
```

## Code Conventions

### Formatting
- **Indentation:** 2 spaces (never tabs, never 4 spaces)
- **Line length:** 100 characters max
- **Charset:** UTF-8
- **Line endings:** LF

### Naming
| Element        | Convention      | Example                       |
|----------------|-----------------|-------------------------------|
| Files          | `snake_case.gd` | `wang_generator.gd`          |
| Classes        | `PascalCase`    | `class_name WangGenerator`   |
| Functions      | `snake_case`    | `func generate_tileset()`    |
| Variables      | `snake_case`    | `var tile_size: int`         |
| Constants      | `UPPER_CASE`    | `const TILE_SIZE = 48`       |
| Enums (type)   | `PascalCase`    | `enum TileRotation { ... }`  |
| Signals        | `snake_case`    | `signal generation_complete()` |
| Signal handlers| `_on_*`         | `func _on_generation_complete():` |
| Private vars   | `_underscore`   | `var _internal_state: int`   |

### GDScript Typing Rules

Treat "inferred Variant type" warnings as **parse errors**. Never use `:=` when the right-hand side returns `Variant`. Common pitfalls:

- `Array.pop_back()`, `Array.pop_front()`, `Array.back()`, `Array.front()` — always return `Variant` even on typed arrays. Use explicit type: `var x: int = arr.pop_back()`
- `Dictionary[key]` — returns `Variant`. Use explicit type: `var x: MyType = dict[key]`
- `for x in [1.0, 2.0]:` — untyped array literals make `x` Variant. Use a typed array: `var arr: Array[float] = [1.0, 2.0]` then `for x in arr:`
- `for key in dict:` — `key` is Variant. Acceptable for iteration but don't use `:=` on expressions derived from it without an explicit type annotation
- Method chains on `Variant` return `Variant`. Use explicit type for results

### Debug Logging
Use module prefixes for all print statements:
```gdscript
print("WANG: Generated %d tiles" % count)
print("GEN: Herringbone pattern built for %s" % region)
```

### UI Rules
- **All UI must be previewable in the Godot editor** — no empty containers populated only at runtime
- **Never create UI nodes in GDScript** — no `Label.new()`, `HBoxContainer.new()`, etc. All structural UI lives in `.tscn` files
- **Never use inline `Color()` literals** — use `@export` vars or resources
- **Never use hardcoded `KEY_*` constants** — define actions in Input Map, check via `event.is_action_pressed()`
- Pattern: `instantiate() -> add_child() -> setup() -> connect signals`

### Data vs Visuals Separation
- Resource classes contain only gameplay data (no textures, sprites, colors)
- Visual assets live in scene files, not data resources
- Visuals belong in `.tscn` scenes — code only toggles visibility and swaps textures at runtime

### Shader Conventions
- Use `group_uniforms` for organized inspector UI
- Include appropriate hints: `filter_nearest`, `source_color`, `repeat_enable`, `hint_range(min, max, step)`
- Nested groups with dot notation: `group_uniforms textures.detail;`

### C++ Conventions (GDExtension)
- **Standard:** C++17
- **Naming:** `PascalCase` classes, `snake_case` methods/variables (matches godot-cpp style)
- **Bindings:** `ClassDB::bind_method()` / `ADD_PROPERTY()` for Godot-facing API
- **Files:** One class per `.h/.cpp` pair, `snake_case` filenames
- **Registration:** All classes registered in `register_types.cpp` at `MODULE_INITIALIZATION_LEVEL_SCENE`
- **Third-party:** Vendored headers in `native_src/thirdparty/`, never modified

## Git
- **NEVER add attribution to commits — no Co-Authored-By, no signatures, no trailers. Plain commit messages only.**
