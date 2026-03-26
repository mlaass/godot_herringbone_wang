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
* **Backend Module:** GDExtension written in C++ wrapping stb\_herringbone\_wang\_tile.h.
* **Frontend Editor:** A GDScript @tool script extending TileMapLayer (the "Authoring Canvas") and standard Editor UI panels.
* **Outputs:** A standard Godot TileMapLayer populated with the generated cell data.

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

### **Phase 1: Editor Canvas & Macro-Tile Extraction**

* Create the HerringboneAuthoringLayer @tool script.
* Implement \_draw() to render the 1:2 / 2:1 bounding boxes and corner vertices.
* Implement the cell-extraction logic to save Godot TileMapCell data into the HerringboneMacroSet resource.

### **Phase 2: GDExtension Core Wrapper**

* Setup GDExtension template.
* Include stb\_herringbone\_wang\_tile.h.
* Create stbhwt\_wrapper.cpp exposing the stochastic generation functions to GDScript.

### **Phase 3: Stitching & Map Generation**

* Implement the populate\_tilemap() function.
* Handle the coordinate math required to seamlessly interlock the $2N \times N$ and $N \times 2N$ rectangular cell grids into a single, unified TileMapLayer.

### **Phase 4: Validation & Examples**

* Build the Inspector validator to warn users of missing color combinations in their complete stochastic sets.
* Build the **Dungeon** and **City** initialized templates using Godot's built-in prototyping textures.

## **7\. References & Source Material**

This project heavily references the work and theoretical models established by Sean Barrett.

* **Core Hub & Overview:** [Herringbone Wang Tiles Project Page](https://nothings.org/gamedev/herringbone/)
* **Original Article:** [Herringbone Tiles (2011)](https://nothings.org/gamedev/herringbone/herringbone_tiles.html)
* **Follow-up on Connectivity & Corner Colors:** [More on Herringbone Wang Tiles (2014)](https://nothings.org/gamedev/herringbone/more_herringbone_tiles.html)
* **Connectivity Rules & Catalogs:** [Wang Tile Pseudo-Connectivity Catalog](https://nothings.org/gamedev/herringbone/connectivity_catalog.html)
* **STB C/C++ Header Implementation:** [stb\_herringbone\_wang\_tile.h (GitHub Raw)](https://raw.githubusercontent.com/nothings/stb/refs/heads/master/stb_herringbone_wang_tile.h)
