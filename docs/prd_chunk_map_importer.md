# **Product Requirements Document (PRD)**

**Product Name:** Chunk Map Importer & Edge-Mode Support

**Parent Addon:** Godot Herringbone Wang Tile Generator (see `docs/initial_prd_herringbone_wang.md`)

**Core Reference:** Sean Barrett's `chunks.png` — [Herringbone Tiles (2011)](https://nothings.org/gamedev/herringbone/herringbone_tiles.html)

## **1\. Executive Summary**

This document specifies a **chunk map importer** for the Herringbone Wang Tile addon and the **edge-mode constraint support** required to use it. The importer takes a pixel-art chunk map image (such as Barrett's `chunks.png`) — where each tile's content is drawn as colored pixels and constraint values are encoded as colored border pixels — and produces a fully populated `HerringboneMacroSet` resource. A new `HerringboneColorTileMapping` resource lets users define how pixel colors map to Godot TileSet atlas coordinates.

This feature closes the loop between Barrett's original 128-tile dungeon dataset and the addon's generation pipeline, enabling users to author chunk maps in any pixel editor and import them directly.

**Key additions:**

* **Edge-mode constraints** — first-class support for stb's 6-edge-type constraint model alongside the existing 4-corner-class model, across the full pipeline (data model → C++ generator → map output).
* **Chunk map importer** — a Godot editor tool that parses chunk map images via a stride algorithm and extracts tiles with their constraints into `HerringboneMacroData` resources.
* **Color-to-tile mapping** — a configurable `HerringboneColorTileMapping` resource that maps pixel colors to `{source_id, atlas_coords, alternative_tile}` triples for tilemap projection.

## **2\. Background**

### **2.1 Barrett's Chunk Map Format**

Sean Barrett's 2010 CRPG used 128 pre-authored rectangular chunks (64 horizontal, 64 vertical) arranged in a single PNG sprite sheet (`chunks.png`). Each chunk is a small pixel-art bitmap where individual pixels represent game-world cells (black = wall, white = floor, etc.). Six constraint pixels sit on each tile's border, encoding the edge type at that position.

The addon ships a sample of this image at `addons/herringbone_wang_generator/assets/chunks.png` (192 × 192 pixels, RGB).

### **2.2 Edge-Mode vs Corner-Mode Constraints**

The stb library supports two constraint modes:

| Property | Corner mode (current) | Edge mode (new) |
|---|---|---|
| `is_corner` | 1 | 0 |
| Color pools | 4 corner classes | 6 independent edge types |
| `num_color` array | 4 values `[c0, c1, c2, c3]` | 6 values `[e0, e1, e2, e3, e4, e5]` |
| Vertex-to-pool mapping | Vertex → class → pool | Vertex → own pool (1:1) |
| Barrett's dungeon | — | `[2, 2, 2, 2, 2, 2]` → 128 tiles |

Both modes store exactly **6 constraint values per tile** (a through f). The positions are the same; only the color-pool assignment differs. The existing `HerringboneMacroData.constraints` array already holds 6 values, so the structural change is in `HerringboneMacroSet` and the C++ generator.

### **2.3 Chunk Map Image Layout**

Barrett's `chunks.png` (192 × 192, N = 10) is laid out as follows:

```
┌──────────────────────────────────────────────┐
│  V-tile section: 4 rows × 16 columns         │  rows 0–95
│  Each V-tile slot: 12 px wide × 22 px tall    │  (content: 10 × 20)
│  (N+2) × (2N+2) per slot, stride = slot size  │
├──────────────────────────────────────────────┤
│  H-tile section: 8 rows × 8 columns          │  rows 96–191
│  Each H-tile slot: 24 px wide × 12 px tall    │  (content: 20 × 10)
│  (2N+2) × (N+2) per slot, stride = slot size  │
└──────────────────────────────────────────────┘
```

Each tile slot contains:
* **1-pixel border ring** — mostly pink (`255, 0, 255`), with 6 non-pink constraint pixels at edge midpoints.
* **Interior content** — the pixel-art cells of the chunk.

Constraint pixel positions per tile (edge-mode, relative to slot origin):

**V tile** (N wide × 2N tall content):
```
     a
  ┌──•──┐
  •b     •e
  │      │
  •c     •f
  └──•──┘
     d
```
* `a` — top short edge center: `(~N/2, 0)`
* `d` — bottom short edge center: `(~N/2, 2N+1)`
* `b`, `c` — left long edge, upper and lower: `(0, ~N/2)`, `(0, ~3N/2)`
* `e`, `f` — right long edge, upper and lower: `(N+1, ~N/2)`, `(N+1, ~3N/2)`

**H tile** (2N wide × N tall content):
```
  ┌──•b─────•e──┐
  •a              •d
  └──•c─────•f──┘
```
* `a` — left short edge center: `(0, ~N/2)`
* `d` — right short edge center: `(2N+1, ~N/2)`
* `b`, `e` — top long edge, left and right: `(~N/2, 0)`, `(~3N/2, 0)`
* `c`, `f` — bottom long edge, left and right: `(~N/2, N+1)`, `(~3N/2, N+1)`

The importer finds constraint pixels by scanning the 1-pixel border ring for non-pink pixels rather than relying on exact positions. This makes it robust to slight position variations between chunk map authors.

### **2.4 Constraint Pixel Colors**

In Barrett's `chunks.png`, the two constraint colors are:
* Yellow `(255, 255, 0)` — edge value 0
* Green `(0, 255, 0)` — edge value 1

The importer must auto-detect the unique constraint colors from the image and assign integer values in discovery order (first unique color = 0, second = 1, etc.).

## **3\. Architecture**

### **3.1 Modified Components**

| File | Change |
|---|---|
| `herringbone_macro_set.gd` | Add `is_corner: bool`, expand `num_colors` to support 6 values, update constraint enumeration for edge mode |
| `herringbone_constraint_catalog.gd` | Add edge-mode schemas (e.g. `hbe-222222`) |
| `herringbone_validator.gd` | Handle edge-mode completeness checks |
| `herringbone_authoring_layer.gd` | Edge-mode vertex drawing (6 edge midpoints instead of 6 corners) |
| `native_src/src/herringbone_generator.h` | Add `is_corner` property, 6-value edge color setter |
| `native_src/src/herringbone_generator.cpp` | Edge-mode `stbhw_config` setup, tile matching, template generation |
| `herringbone_plugin.gd` | Register new custom types |

### **3.2 New Components**

| File | Purpose |
|---|---|
| `herringbone_color_tile_mapping.gd` | Resource mapping pixel colors to TileSet atlas coordinates |
| `herringbone_chunk_importer.gd` | Editor tool that parses chunk map images into `HerringboneMacroSet` resources |

### **3.3 Data Flow**

```
Chunk Map PNG                    HerringboneColorTileMapping
       │                                    │
       ▼                                    ▼
┌─────────────────────────────────────────────────┐
│  HerringboneChunkImporter                       │
│                                                 │
│  1. Read image pixels                           │
│  2. Stride over tile slots (user-provided N,    │
│     section layout, transparency color)         │
│  3. Scan border ring → extract 6 constraints    │
│  4. Read interior pixels → map via ColorMapping │
│  5. Build HerringboneMacroData per tile         │
│  6. Bundle into HerringboneMacroSet             │
└─────────────────────────────────────────────────┘
       │
       ▼
HerringboneMacroSet (.tres)
       │
       ▼
Existing pipeline: HerringboneGenerator → generate_abstract_map → populate_tilemap
```

## **4\. Functional Requirements**

### **4.1 Edge-Mode Data Model**

* **Requirement 4.1.1 — `HerringboneMacroSet` edge-mode flag:**
  Add `@export var is_corner: bool = true`. When `false`, the set operates in edge mode. The `num_colors` array holds 6 values (one per edge type) instead of 4 (one per corner class).

* **Requirement 4.1.2 — Edge-mode constraint enumeration:**
  `_enumerate_constraint_combos(orientation)` must produce the correct combinatorial expansion for edge mode. In edge mode, all 6 constraint positions are independent (no vertex-to-class mapping), so the total is simply `∏ num_colors[i]` for `i` in `0..5`.

* **Requirement 4.1.3 — Edge-mode required tile counts:**
  `get_required_h_count()` and `get_required_v_count()` return `∏ num_colors[i]` for the appropriate 6 edge types. With `[2,2,2,2,2,2]`: 2⁶ = 64 per orientation.

* **Requirement 4.1.4 — Backward compatibility:**
  All existing corner-mode behavior must remain unchanged. `is_corner = true` is the default. Existing saved resources continue to work without migration.

### **4.2 Edge-Mode Constraint Catalog**

* **Requirement 4.2.1 — Edge-mode schemas:**
  Add at minimum one edge-mode schema to `HerringboneConstraintCatalog`:

  | Schema | `num_colors` | Tiles | Description |
  |---|---|---|---|
  | `hbe-222222` | `[2,2,2,2,2,2]` | 128 (64H + 64V) | Barrett's binary dungeon corridors |

* **Requirement 4.2.2 — `create_empty_macro_set` for edge mode:**
  The factory method must set `is_corner = false` and populate `num_colors` with 6 values for edge-mode schemas.

### **4.3 HerringboneColorTileMapping Resource**

* **Requirement 4.3.1 — Resource structure:**
  ```gdscript
  class_name HerringboneColorTileMapping
  extends Resource

  @export var entries: Array[Dictionary] = []
  # Each entry: { "color": Color, "source_id": int,
  #               "atlas_coords": Vector2i, "alternative_tile": int }
  @export var transparency_color: Color = Color(1, 0, 1, 1)  # pink
  ```

* **Requirement 4.3.2 — Lookup API:**
  `find_entry(color: Color) -> Dictionary` — returns the matching entry for a pixel color, using a tolerance of ±2 per channel to handle compression artifacts. Returns an empty cell dictionary `{source_id: -1, atlas_coords: Vector2i(-1, -1), alternative_tile: 0}` for unmatched colors or the transparency color.

* **Requirement 4.3.3 — Transparency handling:**
  Pixels matching `transparency_color` (within tolerance) produce empty cells (`source_id = -1`). This is the default for pink `(255, 0, 255)`.

### **4.4 Chunk Map Importer**

The importer is a `@tool` script providing an editor-accessible import function. It does **not** use `EditorImportPlugin` (which intercepts file loading); instead it exposes a callable method and/or inspector button on `HerringboneAuthoringLayer`.

* **Requirement 4.4.1 — Import configuration:**
  The importer accepts the following parameters (all provided by the user):

  | Parameter | Type | Description |
  |---|---|---|
  | `chunk_map` | `Image` | The source chunk map PNG |
  | `short_side_len` | `int` | N — the short side of each tile in pixels |
  | `transparency_color` | `Color` | Background/separator color (default pink) |
  | `v_section_origin` | `Vector2i` | Top-left pixel of the V-tile section |
  | `v_section_cols` | `int` | Number of V tiles per row |
  | `v_section_rows` | `int` | Number of V tile rows |
  | `h_section_origin` | `Vector2i` | Top-left pixel of the H-tile section |
  | `h_section_cols` | `int` | Number of H tiles per row |
  | `h_section_rows` | `int` | Number of H tile rows |
  | `color_mapping` | `HerringboneColorTileMapping` | Color → atlas coordinate mapping |

  **Barrett defaults:** N = 10, V origin = `(0, 0)`, V cols = 16, V rows = 4, H origin = `(0, 96)`, H cols = 8, H rows = 8.

* **Requirement 4.4.2 — Stride algorithm:**
  Tile slot sizes are computed from N:
  * V-tile slot: `(N + 2)` wide × `(2N + 2)` tall
  * H-tile slot: `(2N + 2)` wide × `(N + 2)` tall

  The importer iterates tile slots by striding through each section:
  ```
  for row in range(section_rows):
    for col in range(section_cols):
      slot_x = origin.x + col * slot_width
      slot_y = origin.y + row * slot_height
      extract_tile(slot_x, slot_y, orientation)
  ```

* **Requirement 4.4.3 — Constraint extraction:**
  For each tile slot, the importer scans the 1-pixel border ring (top row, bottom row, left column, right column of the slot) for non-transparency pixels. These are the constraint pixels. The importer:
  1. Collects all non-transparency border pixels with their positions.
  2. Classifies each by edge: top, bottom, left, or right.
  3. Sorts within each edge by position (left-to-right for top/bottom, top-to-bottom for left/right).
  4. Assigns constraint values by mapping each unique constraint color to an integer (first color seen across the entire image = 0, second = 1, etc.).
  5. Produces a `PackedInt32Array` of 6 constraint values in the canonical order: for V tiles `[a, b, c, d, e, f]` mapped from `[top, left-upper, left-lower, bottom, right-upper, right-lower]`; for H tiles `[a, b, c, d, e, f]` mapped from `[left, top-left, top-right, right, bottom-left, bottom-right]`.

  The importer must validate that exactly 6 constraint pixels are found per tile. Tiles with fewer or more emit a warning and are skipped.

* **Requirement 4.4.4 — Content extraction:**
  Interior pixels (everything inside the 1-pixel border ring) are read and mapped through the `HerringboneColorTileMapping`:
  * For each pixel at content position `(cx, cy)`:
    * Look up the pixel color in the mapping.
    * Store the resulting `{source_id, atlas_coords, alternative_tile}` dictionary.
  * The content grid becomes the `cells` array of a `HerringboneMacroData`, with `width = content_width` and `height = content_height`.

* **Requirement 4.4.5 — Output:**
  The importer produces a `HerringboneMacroSet` resource with:
  * `is_corner = false` (edge mode)
  * `num_colors` derived from the number of unique constraint colors found per edge type
  * `base_unit_size = short_side_len`
  * `h_tiles` and `v_tiles` arrays populated with `HerringboneMacroData` instances
  * Each `HerringboneMacroData` has: `orientation`, `tile_id`, `constraints`, `width`, `height`, `cells`

* **Requirement 4.4.6 — Error reporting:**
  The importer returns a result dictionary:
  ```gdscript
  {
    "success": bool,
    "macro_set": HerringboneMacroSet,  # null on failure
    "errors": PackedStringArray,
    "warnings": PackedStringArray,
    "tiles_imported": int,
    "tiles_skipped": int,
    "unique_content_colors": int,
    "unique_constraint_colors": int,
  }
  ```

### **4.5 C++ Generator Edge-Mode Support**

* **Requirement 4.5.1 — Edge-mode configuration:**
  Add to `HerringboneGenerator`:
  * `set_constraint_mode(is_corner: bool)` — toggles between corner and edge mode.
  * `set_edge_colors(colors: PackedInt32Array)` — accepts 6 values for `num_color[0..5]`.
  * `get_constraint_mode() -> bool` — returns current mode.

* **Requirement 4.5.2 — Edge-mode tileset building:**
  When `is_corner = false`, `build_tileset()` must:
  * Configure `stbhw_config` with `is_corner = 0` and all 6 `num_color` values.
  * Generate the stb template using edge-mode layout.
  * Encode tile IDs into interior pixels using the same pixel proxy scheme (R = tile\_id, G = 0x42, B = 0x42).
  * Parse the template back with `stbhw_build_tileset_from_image()`.

* **Requirement 4.5.3 — Edge-mode map generation:**
  `generate_abstract_map()` must work identically for both modes — stb handles the constraint matching internally. The output format `{tile_id, orientation, grid_x, grid_y}` is unchanged.

* **Requirement 4.5.4 — Edge-mode constraint-to-position mapping:**
  The C++ code must map edge-mode constraint values from `HerringboneMacroData` (which uses the importer's canonical ordering) to stb's internal constraint positions. This mapping is a fixed permutation per orientation, determined by how stb assigns edge types to the 6 vertex positions.

  The exact permutation must be verified during implementation by generating a known template and inspecting the constraint pixel assignments.

* **Requirement 4.5.5 — Backward compatibility:**
  The default mode remains corner (`is_corner = true`). All existing `set_corner_colors()` / `load_tile_definitions()` / `build_tileset()` behavior is unchanged.

### **4.6 Validation Updates**

* **Requirement 4.6.1 — Edge-mode validation:**
  `HerringboneValidator.validate()` must handle edge-mode sets: check completeness against `∏ num_colors[i]` for 6 values, report missing edge-mode constraint combinations.

* **Requirement 4.6.2 — Imported tile validation:**
  After import, the validator should verify:
  * All 6 constraints are within `[0, num_colors[i])` range for each position.
  * No duplicate constraint combinations exist within the same orientation.
  * Cell dimensions match the expected `2N × N` (H) or `N × 2N` (V).

## **5\. Chunk Map Image Specification**

For any chunk map image to be importable, it must conform to:

1. **RGB format** (no alpha channel required; alpha is ignored if present).
2. **A uniform transparency color** used as background and tile-slot separators.
3. **Tile slots arranged in a regular grid** within one or more rectangular sections. Each section contains tiles of a single orientation (H or V).
4. **Each tile slot** is `(2N+2) × (N+2)` pixels for H tiles or `(N+2) × (2N+2)` pixels for V tiles, where N is the short-side length.
5. **A 1-pixel border ring** around each tile slot containing exactly 6 non-transparency pixels (the constraint markers). Remaining border pixels must be the transparency color.
6. **Interior pixels** (the `2N × N` or `N × 2N` content area) use colors defined in the accompanying `HerringboneColorTileMapping`.

## **6\. Implementation Roadmap**

Test-driven development order. Each phase includes GUT tests.

### **Phase 6: Edge-Mode Data Model**

Extends the existing data model (Phases 1–5 from `initial_prd_herringbone_wang.md`).

* Add `is_corner` flag to `HerringboneMacroSet`.
* Expand `num_colors` to support 6 values.
* Implement edge-mode constraint enumeration and required-count logic.
* Add `hbe-222222` schema to `HerringboneConstraintCatalog`.
* Update `HerringboneValidator` for edge-mode completeness.
* **Tests:** `test/unit/test_macro_set_edge_mode.gd`, `test/unit/test_constraint_catalog_edge.gd`.
* **Gate:** All existing corner-mode tests still pass. Edge-mode enumeration produces correct tile counts.

### **Phase 7: Color Tile Mapping Resource**

* Implement `HerringboneColorTileMapping` resource with lookup API.
* **Tests:** `test/unit/test_color_tile_mapping.gd` — tolerance matching, transparency handling, missing color fallback.
* **Gate:** Round-trip serialization, color lookup with tolerance.

### **Phase 8: Chunk Map Importer**

* Implement `HerringboneChunkImporter` with stride algorithm and constraint extraction.
* Import Barrett's `chunks.png` as integration test.
* **Tests:** `test/unit/test_chunk_importer.gd` (stride math, border scanning), `test/integration/test_import_chunks_png.gd` (full import of sample image).
* **Gate:** Importing `chunks.png` with correct config produces a complete `HerringboneMacroSet` with 64 H-tiles and 64 V-tiles, all with valid constraints and non-empty cell data.

### **Phase 9: Edge-Mode C++ Generator**

* Add edge-mode to `HerringboneGenerator` C++ class.
* Wire `set_constraint_mode()`, `set_edge_colors()`.
* Implement edge-mode template generation and tile matching.
* Verify constraint-position mapping with known templates.
* **Tests:** `test/unit/test_edge_mode_generation.gd`, `test/integration/test_generate_edge_mode_map.gd`.
* **Gate:** Generating an abstract map from the imported Barrett set produces valid herringbone placements with constraint satisfaction. Deterministic seed output matches expected values.

### **Phase 10: End-to-End Integration**

* Full pipeline: `chunks.png` → importer → `HerringboneMacroSet` → `HerringboneGenerator` → `generate_abstract_map` → `populate_tilemap`.
* Ship Barrett's dungeon as a working example scene.
* **Tests:** `test/integration/test_chunk_map_end_to_end.gd`.
* **Gate:** A generated dungeon tilemap from the imported chunk set renders correctly and passes connectivity checks.

## **7\. Open Questions**

* **[OPEN QUESTION]** The exact permutation mapping between the importer's canonical constraint ordering and stb's internal edge-type assignment needs verification by inspecting a generated stb edge-mode template. This is an implementation detail that must be resolved in Phase 9.

* **[OPEN QUESTION]** Should the importer also support chunk maps where tile slots are separated by multi-pixel gaps (e.g., 2px pink separators between slots), or is the current 1-pixel-border-ring model sufficient? Barrett's image uses adjacent slots with no extra gap, but other authors may use wider separators.

## **8\. References**

* Parent PRD: `docs/initial_prd_herringbone_wang.md`
* Barrett's herringbone tiles (2011): `docs/ref_herringbone_tiles_2011.md`
* stb API reference: `docs/ref_stb_api.md`
* Sample chunk map: `addons/herringbone_wang_generator/assets/chunks.png`
* Source page: [nothings.org/gamedev/herringbone/herringbone_tiles.html](https://nothings.org/gamedev/herringbone/herringbone_tiles.html)
