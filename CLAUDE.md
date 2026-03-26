# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.6 addon implementing a herringbone Wang tile generator. The addon lives in `addons/herringbone_wang_generator/`. Uses GL Compatibility renderer with Jolt Physics 3D.

See `docs/initial_prd_herringbone_wang.md` for the product requirements.

## Running

Open in Godot 4.6+. No build system — run directly from the Godot editor.

```bash
godot46                    # Open editor
godot46 --headless --quit  # Validate project parses
```

## Testing

After any GDScript or shader change, run headless validation:
```bash
timeout 10 godot46 --headless --path . 2>&1
```
Check for `SCRIPT ERROR`, `Parse Error`, and `Failed to load` in the output.

## Project Structure

```
addons/herringbone_wang_generator/  # The addon (self-contained, installable)
docs/                               # Design documents and PRDs
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

## Git
- **NEVER add attribution to commits — no Co-Authored-By, no signatures, no trailers. Plain commit messages only.**
