# **Product Requirements Document (PRD)**

**Product Name:** Godot Herringbone Wang Tile Generator & Authoring Tool

**Platform:** Godot Engine 4.x (Addon \+ GDExtension)

**Core Library:** stb\_herringbone\_wang\_tile.h (Sean Barrett)

## **1\. Executive Summary**

This document outlines the product requirements for a Godot Addon and GDExtension designed to author and generate Herringbone Wang Tiles.

**Core Paradigm Shift:** Instead of treating Herringbone tiles as single image sprites, this tool treats them as **Macro-Tiles (Chunks)** composed of standard Godot cells. The authoring environment is a Godot TileMapLayer extended with a @tool script. Designers paint standard Godot tiles (walls, floors, props) inside designated 1:2 and 2:1 rectangular bounding boxes directly in the editor. The addon extracts these cell patterns, associates them with Wang corner constraints, and generates vast, aperiodic, organically connected levels (like dungeons or cities) on a target TileMapLayer.

## **2\. Theoretical Background & Mechanics**

To ensure the addon accurately reflects the source material, it will strictly adhere to the following principles derived from the referenced literature:

* **Macro-Tile Ratios & Topology:** Herringbone tiles use rectangles with a 1:2 (horizontal) and 2:1 (vertical) aspect ratio. In Godot terms, if a base square unit is $N \times N$ cells (e.g., $4 \times 4$), a horizontal macro-tile is $2N \times N$ cells ($8 \times 4$), and a vertical macro-tile is $N \times 2N$ cells ($4 \times 8$).
* **Corner Classes:** The addon supports the **four independent corner classes** of the herringbone pattern.
* **Complete Stochastic Sets:** The generator relies on "complete stochastic sets" (creating a macro-tile for every possible combination of allowed corner constraints), allowing ultra-fast $O(1)$ per-tile stochastic generation without backtracking algorithms.
* **Complex Connectivity:** Utilizing Wang tile corner-color constraints, the tool allows developers to guarantee map-wide reachability while generating complex, winding paths (avoiding homogeneously connected, boring maps).

## **3\. Architecture & Tech Stack**

* **Engine version:** Godot 4.x.
* **Backend Module:** GDExtension written in C++ wrapping stb\_herringbone\_wang\_tile.h via **pixel proxy encoding** — tile IDs encoded as RGB pixels (R = type index, G+B = extra info), stb used unmodified. See `docs/ref_stb_api.md`.
* **Frontend Editor:** A GDScript @tool script extending TileMapLayer (the "Authoring Canvas") and standard Editor UI panels.
* **Outputs:** A standard Godot TileMapLayer populated with the generated cell data.
* **Testing:** GUT (Godot Unit Testing) framework with headless CLI runner.

## **4\. Functional Requirements**

### **4.1. Core Data Structures (Custom Resources)**

* **HerringboneMacroSet (Resource):**
  * Stores the base configuration (e.g., $N \times N$ cells per square unit).
  * Contains an array/dictionary of HerringboneMacroData.
* **HerringboneMacroData (Resource):**
  * Sub-resource mapping to a specific layout (Horizontal or Vertical).
  * Stores a 2D array of Godot TileMapCell data (source\_id, atlas\_coords, alternative\_tile).
  * Stores the **6 corner color constraints** corresponding to the macro-tile's vertices.
* **HerringboneConstraintCatalog (Resource):**
  * Pre-loaded connectivity templates (e.g., hbw-2222, wt-3333, wt-4444).

### **4.2. Editor Addon (The @tool Authoring Canvas)**

The primary authoring environment is a custom node: HerringboneAuthoringLayer (extends TileMapLayer).

* **Requirement 4.2.1 \- The Visual Grid:**
  The @tool script overrides \_draw() to render bold rectangular outlines on the canvas, clearly delineating the 1:2 and 2:1 macro-tile zones where the user should paint.
* **Requirement 4.2.2 \- In-Viewport Constraint Painter:**
  The tool script renders clickable, colored circles at the 6 vertices of each macro-tile outline. Clicking a vertex cycles through the allowed colors for that specific corner class.
* **Requirement 4.2.3 \- Cell Extraction:**
  A "Bake TileSet" button in the inspector that scans the TileMapLayer, extracts the cell data within each bounding box, reads the painted corner constraints, and serializes this into a HerringboneMacroSet Resource.
* **Requirement 4.2.4 \- "Missing Tile" Validator:**
  Because complete stochastic sets require exact combinations, the inspector must show a validation panel. If the user specifies a 2,2,2,2 schema (requiring 128 macro-tiles), the addon checks which color combinations are missing and generates empty bounding boxes on the canvas for the user to fill in.

### **4.3. The Generator Engine (GDExtension)**

The C++ layer interfaces with the stb library to generate the macro-layout.

* **Requirement 4.3.1 \- Abstract Map Generation:**
  Expose a method generate\_abstract\_map(schema: Array, width: int, height: int, seed: int) \-\> Array\[Array\[Dictionary\]\]. This returns the mathematical layout of Horizontal and Vertical tiles and their selected constraint IDs.
* **Requirement 4.3.2 \- TileMap Projection:**
  Expose a method populate\_tilemap(target\_layer: TileMapLayer, abstract\_map: Array, macro\_set: HerringboneMacroSet). This iterates through the abstract map, taking the $2N \times N$ and $N \times 2N$ cell arrays from the HerringboneMacroData and plotting them seamlessly onto the final Godot TileMapLayer.

## **5\. Initialized Examples (Based on Nothings.org Data)**

To help users understand the system immediately, the addon will ship with two initialized demo scenes pre-painted on a HerringboneAuthoringLayer.

### **Example 1: The 128-Tile Dungeon (hbw-2222 Schema)**

Based on Sean Barrett's 2010 CRPG dungeon.

* **Base Unit ($N \times N$):** 4 cells ($16 \times 16$ pixels per cell).
* **Dimensions:** Horizontal tiles are $8 \times 4$ cells; Vertical tiles are $4 \times 8$ cells.
* **Constraint Rule:** 2,2,2,2 (2 colors per corner class).
* **Total Macro-tiles:** 64 Horizontal \+ 64 Vertical \= 128 tiles.
* **Content:** Uses standard Godot autotiles for stone walls and dirt floors.
* **Connectivity Logic:** The user paints the "Red" corner as a solid wall vertex, and the "Green" corner as an open floor vertex. The complete stochastic set guarantees fully connected but highly convoluted, non-linear dungeon paths without any dead-ends.

### **Example 2: The Hex-to-Grid City Streets**

Based on the *Infamous* map generation observation (hexagonal connectivity mapped to a rectangular street grid).

* **Base Unit ($N \times N$):** 8 cells.
* **Dimensions:** Horizontal tiles are $16 \times 8$ cells; Vertical tiles are $8 \times 16$ cells.
* **Content:** Roads, sidewalks, and building footprints.
* **Connectivity Logic:** Explores placing road connections *mid-edge* while using the corner constraints to enforce zoning (e.g., Color 0 \= Residential zoning, Color 1 \= Commercial zoning). Buildings are painted crossing the boundaries, hiding the underlying Wang grid completely.

## **6\. Implementation Roadmap**

Test-driven development order. Each phase includes GUT tests. See `docs/ref_stb_api.md` for the pixel proxy encoding strategy that bridges the image-based stb library with abstract tile-ID output.

### **Phase 1: Foundation — stb Download, GDExtension Scaffold, GUT Setup**

* Download and vendor `stb_herringbone_wang_tile.h` (unmodified) into `addons/herringbone_wang_generator/native_src/thirdparty/`.
* Create GDExtension scaffold following the project's established pattern (see `~/workspace/godot-constraint-solving/addons/wfc_native/`):
  * `native_src/SConstruct` — SCons build config, links godot-cpp.
  * `native_src/src/register_types.{h,cpp}` — Extension registration.
  * `herringbone_native.gdextension` — Extension manifest.
  * Compiled `.so`/`.dll` output to `addons/herringbone_wang_generator/`.
* Stub `HerringboneGenerator` C++ class with `generate_abstract_map()` returning empty array.
* Create `.gutconfig.json` at project root and `test/` directory with `unit/`, `integration/`, `smoke/` subdirectories.
* **Tests:** `test/smoke/test_addon_loads.gd`, `test/smoke/test_native_binds.gd`.
* **Gate:** `scons platform=linux target=release` compiles; GUT finds and runs smoke tests.

### **Phase 2: Core Data Structures (GDScript Resources)**

* `HerringboneMacroData` (Resource) — stores 2D cell array + 6 corner constraint values + orientation (H/V).
* `HerringboneMacroSet` (Resource) — container of HerringboneMacroData, indexed by constraint combination.
* `HerringboneConstraintCatalog` (Resource) — predefined connectivity templates (hbw-2222, etc.).
* **Tests:** `test/unit/test_macro_data.gd`, `test/unit/test_macro_set.gd`, `test/unit/test_constraint_catalog.gd`.
* Serialization round-trips, constraint validation, completeness checking.

### **Phase 3: Generator Engine (GDExtension Core — Pixel Proxy)**

* Implement `HerringboneGenerator` C++ class using the **pixel proxy encoding** approach:
  * Accept tile definitions from GDScript (constraint values a–f + tile ID + H/V orientation).
  * Build synthetic template image internally: constraint colors on borders, tile ID encoded in interior pixels (R = tile type 0–255, G+B = extra info).
  * Call `stbhw_build_tileset_from_image()` to load tileset from synthetic image.
  * `generate_abstract_map(width, height, seed) -> Array` calls `stbhw_generate_image()`, decodes output pixels back to tile IDs via dictionary lookup.
* **Tests:** `test/unit/test_herringbone_layout.gd`, `test/integration/test_generate_map.gd`.
* Deterministic seed output, constraint satisfaction verification, boundary handling, pixel encoding round-trip.

### **Phase 4: Editor Canvas & Authoring + Map Projection**

* Create `HerringboneAuthoringLayer` @tool script extending TileMapLayer.
* Implement `_draw()` to render the 1:2 / 2:1 bounding boxes and corner vertices.
* Implement the constraint painter (click-to-cycle corner colors at vertices).
* Implement cell extraction ("Bake TileSet" button → HerringboneMacroSet resource).
* Implement `populate_tilemap()` — projects abstract map onto target TileMapLayer, handling the coordinate math to seamlessly interlock the $2N \times N$ and $N \times 2N$ rectangular cell grids.
* **Tests:** `test/integration/test_cell_extraction.gd`, `test/integration/test_populate_tilemap.gd`.

### **Phase 5: Validation & Examples**

* Build the Inspector validator to warn users of missing color combinations in their complete stochastic sets.
* Build the **128-Tile Dungeon** (hbw-2222 schema) initialized template.
* Build the **Hex-to-Grid City Streets** initialized template.
* **Tests:** `test/integration/test_stochastic_completeness.gd`.

## **7\. References & Source Material**

This project heavily references the work and theoretical models established by Sean Barrett. Full content archived in `docs/` for offline reference.

* **Core Hub & Overview:** [Herringbone Wang Tiles Project Page](https://nothings.org/gamedev/herringbone/) — local: [ref\_hub\_overview.md](ref_hub_overview.md)
* **Original Article:** [Herringbone Tiles (2011)](https://nothings.org/gamedev/herringbone/herringbone_tiles.html) — local: [ref\_herringbone\_tiles\_2011.md](ref_herringbone_tiles_2011.md)
* **Follow-up on Connectivity & Corner Colors:** [More on Herringbone Wang Tiles (2014)](https://nothings.org/gamedev/herringbone/more_herringbone_tiles.html) — local: [ref\_more\_herringbone\_tiles\_2014.md](ref_more_herringbone_tiles_2014.md)
* **Connectivity Rules & Catalogs:** [Wang Tile Pseudo-Connectivity Catalog](https://nothings.org/gamedev/herringbone/connectivity_catalog.html) — local: [ref\_connectivity\_catalog.md](ref_connectivity_catalog.md)
* **STB C/C++ Header Implementation:** [stb\_herringbone\_wang\_tile.h (GitHub Raw)](https://raw.githubusercontent.com/nothings/stb/refs/heads/master/stb_herringbone_wang_tile.h) — local: [ref\_stb\_api.md](ref_stb_api.md)
