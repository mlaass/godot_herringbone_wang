# **Product Requirements Document (PRD)**

**Product Name:** Herringbone Editor Panel

**Parent Addon:** Godot Herringbone Wang Tile Generator (see `docs/initial_prd_herringbone_wang.md`)

**Depends on:** Chunk Map Importer (see `docs/prd_chunk_map_importer.md`)

## **1. Executive Summary**

This document specifies an **editor panel** for the Herringbone Wang Tile addon — a bottom-panel dock that acts as a central hub for the full tile generation workflow. Currently every pipeline step (color detection, chunk map importing, generation, tilemap population) requires writing GDScript code. The panel makes all operations accessible through the Godot editor UI.

**Key decisions:**

* The panel is a **bottom panel tab** (alongside Output/Debugger), built in code via `EditorPlugin.add_control_to_bottom_panel()`.
* It **auto-switches** to itself when the user selects a `TileMapLayer` in the scene tree.
* The pipeline is exposed as **three sequential steps**: Detect Colors → Import → Generate & Place.
* State (import presets, color mappings) **persists via `.tres` resource files** that the user saves to disk.
* **Chunk map import** is the primary workflow. Manual corner-mode authoring support is secondary and may be deferred.

## **2. Problem Statement**

### **2.1 Current State**

| Operation | How it works today |
|---|---|
| Detect content colors from a chunk map | No API exists — user manually guesses colors |
| Create color-to-tile mapping | Construct `Array[Dictionary]` in code or call `populate_from_atlas()` |
| Import a chunk map | Write ~15 lines of GDScript calling `HerringboneChunkImporter` with 10 parameters |
| Configure & run the C++ generator | ~10 lines of GDScript: instantiate, set mode, load defs, build, generate |
| Populate a TileMapLayer | Call `HerringboneAuthoringLayer.populate_tilemap()` with correct arguments |
| Validate an imported tile library | Call `HerringboneValidator.validate()` and interpret the result dictionary |

Every operation requires the user to write and run GDScript. There is no editor UI for any of these steps.

### **2.2 Desired State**

A single bottom-panel tab where the user:

1. Picks a chunk map image and clicks **Detect Colors** → gets a `.tres` mapping resource with all discovered colors, ready to edit in the inspector.
2. Selects an import preset (or enters custom parameters) and clicks **Import** → the tile library is built in memory and validated.
3. Sets seed and map size, clicks **Generate & Place** → the selected TileMapLayer is populated.

Each step shows inline status feedback. No GDScript required.

## **3. Goals and Non-Goals**

### **3.1 Goals**

* **Zero-code chunk map workflow** — a user with a chunk map PNG and a TileSet can go from image to populated tilemap entirely through the editor UI.
* **Discoverable color mapping** — automatically scan a chunk map for content colors and produce an editable resource, so users don't have to guess hex values.
* **Persistent configuration** — import presets and color mapping resources saved as `.tres` files, portable across sessions and projects.
* **Inline feedback** — each step reports results (colors found, tiles imported, tiles placed) directly in the panel.

### **3.2 Non-Goals (deferred)**

* **Manual corner-mode authoring UI** — the existing `HerringboneAuthoringLayer` handles this workflow. The panel may add bake/validate buttons for it in a future PRD, but the initial implementation focuses on chunk map import.
* **Live preview** — no real-time minimap or tile preview in the panel. The user sees results on the TileMapLayer in the 2D viewport.
* **Undo/redo integration** — tilemap population is a bulk operation. Undo support is a future enhancement.
* **Multi-TileMapLayer support** — the panel targets one TileMapLayer at a time.

## **4. Target User Experience**

### **4.1 Opening the Panel**

The panel tab labeled "Herringbone" appears in the bottom panel area when the addon is enabled. When the user selects a `TileMapLayer` node in the scene tree, the editor auto-switches to the Herringbone tab.

The panel header shows the name of the currently selected `TileMapLayer`, or "No TileMapLayer selected" with a prompt to select one.

### **4.2 Step 1 — Detect Colors**

```
┌─ Detect Colors ──────────────────────────────────────────────────┐
│  Chunk Map: [                          ] [Browse...]             │
│  Transparency: [████ (1, 0, 1) ▼]                               │
│                                                                  │
│  [Detect Colors]                                                 │
│  ✓ Found 2 content colors (excluded 1 transparency)              │
└──────────────────────────────────────────────────────────────────┘
```

**Controls:**
* **Chunk Map** — file picker for the source PNG image (e.g. `chunks.png`).
* **Transparency Color** — color picker, defaults to pink `(1, 0, 1)`.
* **Detect Colors** button — scans the image for unique non-transparency colors, opens a file-save dialog for the user to choose where to save the resulting `HerringboneColorTileMapping` resource.

**Behavior:**
1. Load the image and iterate all pixels.
2. Collect unique colors (using ±5/255 tolerance grouping), excluding the transparency color.
3. Create a `HerringboneColorTileMapping` resource with one entry per discovered color. Each entry has the detected `color` and placeholder values: `source_id = -1`, `atlas_coords = (-1, -1)`, `alternative_tile = 0`.
4. Prompt the user with a file-save dialog.
5. Save the resource as `.tres`.
6. Show inline status: "✓ Found N content colors. Saved to res://path/to/mapping.tres"

The user then opens the saved `.tres` in the inspector and assigns `source_id` and `atlas_coords` to each color entry, mapping detected chunk-map colors to their TileSet atlas tiles.

### **4.3 Step 2 — Import**

```
┌─ Import ─────────────────────────────────────────────────────────┐
│  Chunk Map: [                          ] [Browse...]             │
│  Color Mapping: [                      ] [Browse...]             │
│  Preset: [Barrett chunks.png ▼]                                  │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄                            │
│  Short Side (N): [10]     Transparency: [████ (1, 0, 1) ▼]      │
│  V Origin: [(0, 0)]  Cols: [16]  Rows: [4]                      │
│  H Origin: [(0, 96)] Cols: [8]   Rows: [8]                      │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄                            │
│  [Import from Chunk Map]  [Load from File...]  [Save Preset...]  │
│  ✓ Imported 125 tiles (64 H + 61 V), 3 skipped                  │
│  ⚠ Validation: 83 unique constraint combos (64.8%)               │
└──────────────────────────────────────────────────────────────────┘
```

**Controls:**
* **Chunk Map** — file picker for the source PNG (shared with Detect Colors if already set).
* **Color Mapping** — resource picker for the `HerringboneColorTileMapping` `.tres` saved in Step 1.
* **Preset** dropdown — built-in presets populate the parameter fields. "Barrett chunks.png" is built-in. "Custom" allows freeform input. Users can save custom presets via "Save Preset..." button.
* **Parameter fields** — `short_side_len`, transparency color, V/H section origins, columns, and rows. Populated by preset selection, editable for custom layouts.
* **Import from Chunk Map** button — runs `HerringboneChunkImporter.import_chunk_map()` with the configured parameters.
* **Load from File...** button — opens a file dialog to load a previously saved `HerringboneMacroSet` `.tres` resource directly, skipping chunk map import. Supports the manual authoring workflow.
* **Save Preset...** button — saves the current parameter values as a named preset `.tres` file.

**Behavior:**
1. Validate inputs (image loaded, mapping assigned, N > 0).
2. Call `import_chunk_map()` with the configured parameters.
3. Run `HerringboneValidator.validate()` on the result.
4. Store the imported tile library in memory (not saved to disk — re-imported each time).
5. Show inline status with tile counts, skipped count, and validation summary.
6. Show any warnings from the importer.

**Built-in presets:**

| Preset | N | V Origin | V Cols | V Rows | H Origin | H Cols | H Rows |
|---|---|---|---|---|---|---|---|
| Barrett chunks.png | 10 | (0, 0) | 16 | 4 | (0, 96) | 8 | 8 |

### **4.4 Step 3 — Generate & Place**

```
┌─ Generate & Place ───────────────────────────────────────────────┐
│  Map Width: [20]    Map Height: [20]    Seed: [42]               │
│  Fallback Tile: [source: 0, atlas: (0,0) ▼]                     │
│                                                                  │
│  [Generate & Place]                                              │
│  ✓ Generated 170 placements, populated TileMapLayer "Dungeon"    │
└──────────────────────────────────────────────────────────────────┘
```

**Controls:**
* **Map Width / Height** — integer spinboxes for the generation grid size.
* **Seed** — integer spinbox for the RNG seed.
* **Fallback Tile** — source_id + atlas_coords for tiles placed when a constraint combo has no matching imported tile. Defaults to the first tile in the TileSet (wall).
* **Generate & Place** button — runs the full generation and population pipeline.

**Behavior:**
1. Require a tile library from Step 2 (show error if not imported yet).
2. Require a selected `TileMapLayer` with a `TileSet` assigned.
3. Instantiate `HerringboneGenerator`, configure edge/corner mode from the tile library's `is_corner` flag.
4. Set colors, load definitions, build tileset, generate abstract map.
5. Clear the target `TileMapLayer`.
6. Call `populate_tilemap()` with the abstract map, tile library, and fallback cell.
7. Show inline status with placement count and target layer name.

## **5. Architecture**

### **5.1 New Components**

| File | Purpose |
|---|---|
| `herringbone_editor_panel.gd` | `@tool` script building the bottom panel UI and orchestrating all workflow steps |

### **5.2 Modified Components**

| File | Change |
|---|---|
| `herringbone_plugin.gd` | Register bottom panel via `add_control_to_bottom_panel()`, handle scene tree selection signals |
| `herringbone_color_tile_mapping.gd` | Add `detect_colors_from_image(image, transparency_color)` method |

### **5.3 New Resource Type**

| File | Purpose |
|---|---|
| `herringbone_import_preset.gd` | Resource storing import parameters (N, section layout) for preset persistence |

### **5.4 Unchanged Components**

| File | Notes |
|---|---|
| `herringbone_chunk_importer.gd` | Used as-is by the panel |
| `herringbone_macro_set.gd` | Used as-is (`to_generator_defs()`) |
| `herringbone_macro_data.gd` | No changes |
| `herringbone_validator.gd` | Used as-is |
| `herringbone_authoring_layer.gd` | `populate_tilemap()` used as-is |
| `herringbone_constraint_catalog.gd` | No changes |
| Native C++ generator | No changes |

### **5.5 Panel ↔ Plugin Integration**

```
EditorPlugin (herringbone_plugin.gd)
  │
  ├── _enter_tree()
  │     ├── Create HerringboneEditorPanel instance
  │     └── add_control_to_bottom_panel(panel, "Herringbone")
  │
  ├── _exit_tree()
  │     └── remove_control_from_bottom_panel(panel)
  │
  ├── _handles(object) → true if object is TileMapLayer
  │
  └── _make_visible(visible)
        └── Show/hide panel, update target reference
```

When the user selects a `TileMapLayer`, Godot calls `_handles()` → `true`, then `_make_visible(true)`. The plugin passes the selected node to the panel. When selection changes away, `_make_visible(false)` is called.

## **6. Functional Requirements**

### **6.1 Color Detection**

* **Requirement 6.1.1 — `detect_colors_from_image` method:**
  Add to `HerringboneColorTileMapping`:
  ```gdscript
  func detect_colors_from_image(
    image: Image,
    transparency_color: Color = Color(1, 0, 1, 1),
  ) -> void:
  ```
  Scans all pixels in the image. Groups unique colors using ±5/255 tolerance. Excludes the transparency color. Populates `entries` with one entry per unique color, using placeholder atlas coordinates (`source_id = -1`, `atlas_coords = (-1, -1)`).

* **Requirement 6.1.2 — File save dialog:**
  After detection, the panel opens an `EditorFileDialog` in save mode (`.tres` filter) so the user chooses where to save the mapping resource.

### **6.2 Import Presets**

* **Requirement 6.2.1 — `HerringboneImportPreset` resource:**
  ```gdscript
  class_name HerringboneImportPreset
  extends Resource

  @export var preset_name: String = ""
  @export var short_side_len: int = 10
  @export var transparency_color: Color = Color(1, 0, 1, 1)
  @export var v_section_origin: Vector2i = Vector2i(0, 0)
  @export var v_section_cols: int = 16
  @export var v_section_rows: int = 4
  @export var h_section_origin: Vector2i = Vector2i(0, 96)
  @export var h_section_cols: int = 8
  @export var h_section_rows: int = 8
  ```

* **Requirement 6.2.2 — Built-in Barrett preset:**
  A static factory method `create_barrett() -> HerringboneImportPreset` returns the default Barrett `chunks.png` layout.

* **Requirement 6.2.3 — Preset saving:**
  "Save Preset..." button opens a file-save dialog. The current field values are saved as a `HerringboneImportPreset` `.tres` file.

* **Requirement 6.2.4 — Preset loading:**
  The preset dropdown lists the built-in Barrett preset plus any `.tres` files the user selects via a "Load Preset..." option. Selecting a preset populates all parameter fields.

### **6.3 Panel UI Construction**

* **Requirement 6.3.1 — Code-built UI:**
  The panel is constructed entirely in GDScript using Godot's Control nodes (VBoxContainer, HBoxContainer, Button, SpinBox, Label, ColorPickerButton, etc.). No `.tscn` scene file.

* **Requirement 6.3.2 — Layout:**
  Three collapsible sections arranged vertically:
  1. **Detect Colors** — chunk map picker, transparency color, detect button, status label.
  2. **Import** — chunk map picker, mapping picker, preset dropdown, parameter fields, import button, status label.
  3. **Generate & Place** — size/seed spinboxes, fallback tile config, generate button, status label.

  The chunk map file picker is shared between sections 1 and 2 — setting it in one updates the other.

* **Requirement 6.3.3 — Target display:**
  A header bar at the top shows "Target: NodeName" (the selected TileMapLayer) or "No TileMapLayer selected" with greyed-out controls.

### **6.4 Scene Tree Integration**

* **Requirement 6.4.1 — Auto-switch:**
  When the user selects a `TileMapLayer` in the scene tree, the editor switches to the Herringbone bottom panel tab. The plugin implements `_handles(object) -> bool` returning `true` for `TileMapLayer` nodes.

* **Requirement 6.4.2 — Target tracking:**
  The panel stores a reference to the currently selected `TileMapLayer`. If the node is deleted or deselected, the panel shows "No TileMapLayer selected" and disables action buttons.

### **6.5 Status Feedback**

* **Requirement 6.5.1 — Inline status:**
  Each step section has a `Label` below its action button showing the result of the last operation:
  * Detect Colors: "✓ Found N content colors. Saved to res://..."
  * Import: "✓ Imported N tiles (H + V), M skipped" plus validation summary.
  * Generate & Place: "✓ Generated N placements, populated TileMapLayer 'Name'"

* **Requirement 6.5.2 — Error display:**
  Errors show in red text in the same status label: "✗ Error: chunk_map is null" or "✗ No TileMapLayer selected".

* **Requirement 6.5.3 — Warning display:**
  Warnings (e.g. skipped tiles, incomplete validation) show in yellow text.

## **7. Implementation Phases**

### **Phase 1: Panel Shell + Color Detection**

* Create `herringbone_editor_panel.gd` with the three-section layout (detect, import, generate).
* Register in `herringbone_plugin.gd` as bottom panel.
* Implement Detect Colors section: file picker, color picker, detect button, save dialog.
* Add `detect_colors_from_image()` to `HerringboneColorTileMapping`.
* Implement auto-switch on TileMapLayer selection.
* **Gate:** Selecting a TileMapLayer shows the panel. Clicking Detect Colors on `chunks.png` produces a `.tres` with 2 color entries.

### **Phase 2: Import Section**

* Create `HerringboneImportPreset` resource with Barrett factory method.
* Implement Import section: mapping picker, preset dropdown, parameter fields, import button.
* Wire up the import pipeline: load image, load mapping, call `import_chunk_map()`, validate.
* Show inline status with tile counts and validation summary.
* **Gate:** Selecting Barrett preset and clicking Import shows "125 tiles imported" with validation percentage.

### **Phase 3: Generate & Place Section**

* Implement Generate & Place section: size/seed spinboxes, fallback config, generate button.
* Wire up the generation pipeline: instantiate generator, configure, build, generate, populate.
* Clear TileMapLayer before populating.
* Show inline status with placement count.
* **Gate:** Full workflow works: Detect Colors → edit mapping in inspector → Import → Generate & Place → tiles appear on TileMapLayer.

### **Phase 4: Preset Persistence**

* Implement "Save Preset..." button with file dialog.
* Implement "Load Preset..." option in the preset dropdown.
* **Gate:** Save a custom preset, reload the editor, load the preset, values match.

## **8. Edge Cases**

* **No TileMapLayer selected** — all action buttons disabled, header shows prompt message.
* **TileMapLayer has no TileSet** — Generate & Place shows error "TileMapLayer has no TileSet assigned".
* **Chunk map image fails to load** — status shows "✗ Failed to load image: path".
* **Color mapping has unmapped colors** (`source_id = -1`) — Import proceeds but tiles with unmapped content colors produce empty cells. Status warns: "⚠ N colors in mapping have no atlas assignment".
* **Import produces 0 tiles** — status shows error with the importer's error/warning messages.
* **No tile library imported when Generate clicked** — status shows "✗ Import tiles first".
* **Selected TileMapLayer is deleted** — panel detects null reference, reverts to "No TileMapLayer selected" state.
* **Very large map dimensions** — no hard limit, but generation is synchronous. Sizes above 100×100 may cause editor stalls. Document this as a known limitation.

## **9. Testing Strategy**

* **Unit tests** for `detect_colors_from_image()` — verify color grouping with tolerance, transparency exclusion, entry structure.
* **Unit test** for `HerringboneImportPreset` — verify Barrett factory values, round-trip serialization.
* **Integration test** — the full pipeline called programmatically (detect → import → generate → populate) to verify end-to-end wiring without the UI layer.
* **Manual testing** — open the editor, enable the addon, select a TileMapLayer, walk through all three steps. Verify inline status messages, file dialogs, preset loading.

## **10. Resolved Design Decisions**

* **Color filtering:** Detect Colors finds all non-transparency colors including constraint colors (yellow, green). The user manually deletes unwanted entries from the saved mapping resource. No auto-filtering.

* **Load tile library:** The Import section includes a "Load from File..." button that loads a previously saved `HerringboneMacroSet` `.tres` directly, skipping the chunk map import. This supports the manual authoring workflow (`HerringboneAuthoringLayer` → `bake_macro_set()` → save → load in panel → generate).

## **11. References**

* Parent PRD: `docs/initial_prd_herringbone_wang.md`
* Chunk Map Importer PRD: `docs/prd_chunk_map_importer.md`
* Existing editor integration: `addons/herringbone_wang_generator/herringbone_plugin.gd`
* Example workflow: `example/dungeon_example.gd`
