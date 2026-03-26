<!-- Source: https://nothings.org/gamedev/herringbone/connectivity_catalog.html -->
<!-- Fetched: 2026-03-26 -->

# Wang Tile Pseudo-Connectivity Catalog

Sean Barrett, Silver Spaceship Software
2017-06-27

---

## Overview

This catalog documents connectivity patterns achievable through Wang tile corner-color constraints. It covers 227 connectivity patterns using Wang tiles and herringbone Wang tiles.

## Core Concept

Each tile contains something like a "room", and corridors are created that cross the edges. The connectivity is controlled entirely by tile content and corner-color constraints rather than explicit code logic. This makes the connectivity **data-driven** — different tile sets produce different connectivity behaviors while maintaining local coherence.

## Connectivity Measurement

Connectivity is measured using the **right-hand maze-solving rule** analysis — tracing loops from any starting room back to itself. Different constraint rules produce varying loop-length distributions, characterizing connectivity behavior while maintaining overall connectedness.

## Corner Colors vs. Edge Colors

The system uses **corner-color** Wang tiles rather than traditional edge-colored variants:
- Random access is straightforward; Wang corner colors compute an independent corner-color at every grid vertex
- Corner constraints naturally produce more varied connectivity than edge constraints

## Five Tiling Strategies Analyzed

| Strategy | Colors | Tile Count |
|----------|--------|-----------|
| Regular Wang (4 corners) | 2 colors | 16 tiles |
| Herringbone Wang | 2,2,2,2 | 256 tiles |
| Square Wang (4 artificial classes) | 2,2,2,2 | 64 tiles |
| Square Wang (4 artificial classes) | 3,2,2,2 | 96 tiles |
| Square Wang (4 artificial classes) | 4,2,2,2 | 128 tiles |

## Three Connectivity Categories

1. **Periodic**: Highly regular, repetitive patterns with predictable structure
2. **Near-Periodic**: Mostly uniform with occasional variations
3. **Non-Periodic**: Complex, irregular patterns; subdivided into configurations with and without dead-ends

## Extensions

Two approaches enhance connectivity complexity:
- **Herringbone tiles**: Naturally possess four independent corner classes
- **Artificial corner classes**: Regular square tiles can have artificially imposed corner classes (typically four) to increase variation

## Tile Set Requirements

The number of required tiles scales dramatically with color choices:
- Regular Wang tiles, 2 colors: 16 tiles
- Wang tiles with 4 artificial classes, 2 colors each: 64 tiles
- Full 4-color regular Wang tiles: 256 tiles

## Key Schemas Referenced in the PRD

- **hbw-2222**: Herringbone Wang tiles with 2 colors per corner class = 128 tiles (64H + 64V). Used for the dungeon example.
- **wt-3333**: Standard Wang tiles with 3 colors per artificial corner class
- **wt-4444**: Standard Wang tiles with 4 colors per artificial corner class

## Practical Application

Rather than employing procedural code to control connectivity, designers can "make the connectivity data-driven" through tile set design choices, enabling different behavioral patterns while maintaining local coherence. The catalog serves as a reference for choosing which connectivity pattern best suits a given game's needs.
