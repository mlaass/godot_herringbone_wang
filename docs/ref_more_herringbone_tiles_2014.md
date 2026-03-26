<!-- Source: https://nothings.org/gamedev/herringbone/more_herringbone_tiles.html -->
<!-- Fetched: 2026-03-26 -->

# More on Herringbone Wang Tiles (2014)

Sean Barrett (@nothings), Silver Spaceship Software
2014-07-07

Follow-up to the [original 2011 paper](ref_herringbone_tiles_2011.md).

---

In the prior paper (BARRETT11), I described the fundamentals of "Herringbone Wang Tiles", based on the traditional edge-constrained version of Wang Tiles. A note mentioned the possibility of applying "corner colors" for Wang Tiles to Herringbone Wang Tiles. Implicitly, I was especially concerned with the application of "level generation", in which the generated tilings are examined closely by humans and want to have some specialized properties.

This follow-up paper explores several issues:

1. Looking more closely at results
2. Application of "colored corners" to Herringbone Wang Tiles
3. A more sophisticated approach to complex connectivity using corner colors
4. Applicability to non-herringbone Wang tiles

All the datasets examined in this paper (and a few more) have been made freely available (placed in the public domain). Additionally the C/C++ program used to generate the tilings (as well as to create the tile templates) has been library-ised and also placed in the public domain.

## 1. Looking more closely at results

In BARRETT11, only a single tileset was presented, and that tile set did not actually use any constraints at all. This section presents more results and explores one aspect of the original result more closely.

Results are presented with each image-sprite-tile as a single pixel — mainly about layout and connectivity, not visual appeal.

### Alternate data sets

Additional datasets with various sizes and connectivity models:

#### Small data sets (32 tiles)
- Square rooms with random rects — embraces the grid
- Rooms and corridors with diagonal bias — shows significant herringbone diagonal bias

#### Medium data sets (48-54 tiles)
- Round rooms with diagonal corridors — heavily diagonal due to tile data, not the herringbone pattern; note the seemingly free-form distribution of circles
- Horizontal corridors — leverages horizontal tiles for horizontally-biased output; herringbone diagonal visible if you know to look
- Rooms and corridors — general mixed approach

#### Large data sets (128 tiles)
- Open areas
- Rooms with limited connectivity
- Simple caves (2 wide) — underlying grid apparent but probably unobjectionable
- Caves with limited connectivity
- Corner caves — grid pretty much undetectable

### Complex Connectivity Analysis

The prior paper claimed that generated maps exhibited complex connectivity. This section investigates using "right-hand rule" maze-followings with dead-ends eliminated.

Because of the way the data guarantees full connectivity, there are never dead-ends on a large scale. Solid (unpassable) regions are always semi-locally bounded — they can never extend for more than a few tiles. Any white region is reachable from any other white region, but the black regions are divided into relatively small islands.

A right-hand maze rule will keep a single black island on its right the entire time, and will eventually loop around to its starting place.

#### Path analysis of 5 marked paths:

1. A meandering path with one omitted dead-end
2. A simple, short path, with omitted two dead-ends
3. A long, meandering path
4. Another long but straighter path
5. A path with an odd bend at one end

In every case, the basic pattern is a 3x2 or 2x3 half-tiles and **5 wang tiles**. That is because this model of connectivity always has a worst case of involving 5 tiles. If a path from data created under this model required more than 5 tiles, it would mean there was an error in the data, and connectivity would no longer be guaranteed.

The physical paths do not follow the abstract connectivity very closely, although they never deviate "too far" — for each segment of an abstract path that falls within a single tile, the corresponding physical path cannot leave that tile while still connecting the same endpoints.

## 2. Colored corners

Based on [An alternative for Wang tiles: Colored edges versus colored corners](http://graphics.cs.kuleuven.be/publications/LD06AWTCECC/) by Lagae and Dutre.

### Colored corners for Wang tiles

Primary benefit: in an edge-tile system, the data output across diagonally adjacent tiles is unconstrained (for the full stochastic set); thus corners do not look very good.

Lagae and Dutre note that Wang corner tiles move the diagonal-adjacency problem to an edge adjacency problem; while Wang tiles do not meet cleanly at corners, Wang corner tiles do not meet cleanly at the center of edges. However, this limitation can be solved by introducing redundant edge constraints, coloring each edge to be unique to its two corner colors, then choosing data at the edge midpoint based on those constraints.

### Colored Corners for Herringbone Wang Tiles

While square Wang tiles have 2 distinct edge orientations and hexagonal Wang tiles have 3, herringbone Wang tiles have **6 distinct edge "orientations"**.

For vertices: each rectangular tile has 6 vertices (four corners and two long-edge-midpoints). The vertices of the tiled plane can be grouped into **4 independent classes**.

This independence means colors of each class are actually independent. This creates a degree of freedom in the Wang tile formulation:

- Minimal complete stochastic set is NOT necessarily 2^6 tiles per orientation
- Different numbers of colors can be assigned to each vertex type
- Example: (2,2,2,1) colors requires 32 horizontal + 16 vertical tiles (instead of 64+64)
- Example: (3,1,3,1) colors requires 27 tiles of each type

### Authoring tile-map tiles

The original dataset placed rooms fully within Wang tiles, only allowing corridors to cross boundaries. Given edge or corner constraints, it is also possible to place coherent human-designed features across tile boundaries.

#### Feature placement trade-offs

With 2 colors for corners and 128 tiles:

| Coloring | Feature placement | # unique content items |
|----------|------------------|----------------------|
| any | middle of (half-) tile | 128 (256 correlated) |
| corner colors | corners | 8 |
| corner colors | edges | 24 |
| edge colors | edges | 12 |

Mid-tile is a lot more inviting in terms of ROI; the main reason to use edge content would be because the grid is too visible with only mid-tile content.

## 3. Complex connectivity using colored corners

Using colored corners, we can do better than the 5-tile worst-case loops from section 1, introducing more complicated connectivity with **loops crossing 9-10 tiles**.

### Pair-wise half-tile connectivity

Basic model: make each corner responsible for guaranteeing that the **four half-tiles immediately surrounding that corner must all be connected**.

This guarantees every half-tile is connected to every other half-tile: between any two arbitrary half-tiles, you can find a path of orthogonally-connected half-tiles between them, and then the corners adjacent to each pair guarantee connectivity between those two half tiles; transitively the ends of the path are connected.

### Induction over corner types

The trick: treat the four types of corners differently using induction:

- **Type 1 (red/grey)**: Guarantee outright with U-shaped connections ensuring all four surrounding vertices are connected. Two variation strategies for variety.
- **Type 2 (yellow/blue)**: Adjacent red/grey corners already guarantee some connections. Only need to add one explicit edge.
- **Type 3**: Again gets two guaranteed connections from red/grey corners. Only need to add one new edge.
- **Type 4**: Every adjacent corner is of a type that has already been inducted, so every vertex is already fully-connected. No network edges need to be introduced.

In every case, non-required edges can always be added using edge colors to make the choice consistent across all tiles.

### Connectivity alternatives

Other viable strategies may exist but have not been explored. The presented approach may be "overly connected" since the fourth corner type already has one more guaranteed indirect connection than needed.

Note: program code can make *global* connectivity guarantees or allow maze-like connectivity where there is only a single path between any two points. These constraints cannot be achieved using Wang tile design alone.

## 4. Applicability to non-herringbone Wang tiles

The material about distinct edge orientations and vertex types can be applied to regular Wang tiles by introducing such distinctions artificially.

With four corner "types" each having two colors, this is exactly the same as one corner type with 8 colors; the difference being that the full-stochastic-set for four-types-two-colors is not a full-stochastic-set for 8-colors:
- Four-types-two-colors: **2^4 = 16 tiles**
- One-type-eight-colors: **8^4 = 4096 tiles**

For algorithms assuming the full stochastic set, you can't directly use this technique. However, it's not difficult to modify the algorithm: with two colors per corner, the effective color at each corner uses 1 pseudo-random bit and 2 non-random bits which are structured to guarantee an appropriately-colored tile exists.
