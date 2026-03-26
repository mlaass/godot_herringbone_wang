<!-- Source: https://nothings.org/gamedev/herringbone/herringbone_tiles.html -->
<!-- Fetched: 2026-03-26 -->

# Herringbone Wang Tiles (2011)

Sean Barrett, Silver Spaceship Software
Originally written 2010, published 2011-10-22.

This is the original (unfinished) paper describing Herringbone Wang Tiles.

---

## Herringbone Tiles

The author describes an expansion of the Wang Tiles technique for generating large 2D regions from smaller ones. The method is called "Herringbone Wang Tiles" or "Herringbone Tiles" and is relevant to the map system used in *Infamous* by Sucker Punch.

For an unreleased indie CRPG developed in 2010, the author employed a straightforward dungeon map generation method involving assembly of large maps from small rectangular tiles. Each tile was chosen from a set of 128 pre-authored tiles (themselves composed of small image sprites). The map algorithm was trivial: every tile was randomly selected with no constraints from neighboring tiles or enforced connectivity.

The primary technique enabling this approach is the author's novel method for synthesizing large 2D regions from small tiles using a herringbone tiling pattern. This approach reduces the obviousness of regular tiling and allows superior connectivity without additional computation.

A second technique, called *jigsaw colors*, allows edge shapes to vary to help break up straight edges of normal tiling. This technique is mentioned but not explored further in the paper.

## Wang Tiles

The core concept is based on Wang Tiles. The straightforward approach involves creating small tiles with various edge constraints and randomly generating maps by placing tiles that satisfy existing edge constraints. Edge constraints are domain-specific; for dungeons, a constraint might specify that "for type #1, there's a 10-foot wide passage at the center of the edge."

With square Wang Tiles, a trivial left-to-right, top-to-bottom generator can be used. At each step, a tile must satisfy at most two edge constraints from already-generated adjacent tiles. With two edge colors (two possible constraints per edge), four constraint cases exist. As long as one tile exists for each case, automatic tiling generation is possible.

However, "more than one tile for each case" is necessary to avoid repetition.

### Complete Stochastic Sets

One theory suggests that for optimal results, enough tiles should exist for each case to accommodate every possible "output" edge combination. This limits tile choice at a given location to influencing only immediate neighbors, with no effect on distant tiles.

- With 2 edge variations per edge type: minimum **16** pre-authored tiles
- With 3 variations: minimum **81** tiles

Such a collection is called a **"complete stochastic set."**

The canonical Wang Tiles paper, "Wang Tiles for Image and Texture Generation" by Cohen et al, uses only 2 tiles per constraint case; with three edge variations and 9 total cases, they employ only 18 tiles. They provide no particular argument for why this suffices for good visual results, nor any mechanism for constructing a "good" tile color pattern set for given constraints.

By comparison, the complete stochastic set approach requires no design process for determining color sets (one constructs exactly one preauthored tile for every possible constraint combination). While this requires significantly more content, it eliminates the undefined design process.

### Benefits of Complete Stochastic Sets

- Guarantees tile choices influence only one neighbor
- Trivially supports pre-placement of regular and large tiles before stochastic generation
- No need for solver algorithms — generation is O(1) per tile

The drawback is substantial content requirements (16 tiles for 2 edge constraints, 81 tiles for 3 constraints). Still, the complete stochastic set is worth using if required content is comparable to desired generation amount.

### Large Tiles

Sometimes "special content" larger than a single tile proves useful within a Wang Tile system. For textures, this might be a unique ground formation; for city generation, a large convention center covering multiple blocks; for dungeons, a large cavern.

Handling such regions within the Wang Tile formalism is trivial: given a 2:1 rectangle, split it into two squares and introduce a new, unique color at the boundary. However, this approach fails with the simple stochastic generator — after placing the first square, a unique constraint exists on the adjacent square, but another constraint already exists from the previous tile row.

Using the complete stochastic set makes the filling algorithm trivial, guaranteeing a tile exists matching every possible constraint combination on every edge. Generation returns to left-to-right, top-to-bottom, requiring only generator awareness of additional constraints from pre-generated special tiles.

### Rotation

Allowing tile rotation or mirroring is possible but complicates edge constraint nature: with 90-degree rotation, horizontal edge constraints must match vertical ones. If mirroring or 180-degree rotation is allowed, edge constraints must be internally symmetric. The advantage is that rotation or mirroring allowance decreases minimum needed tiles.

### Issues with Wang Tiles

Some artifacts may be visible when generating maps with Wang Tiles:

1. **Grid visibility**: Edges are adjacent in straight lines, so if edges have particular features or bias, that straight line becomes visible when zoomed out.
2. **Connectivity**: If each edge constraint controls corridor connections between tiles and tiles are limited to one corridor per edge, tracking internal edge connections and overall map connectivity becomes complex.

All tiles can be made internally fully-connected, guaranteeing map connectivity, but resulting homogenous connectivity lacks interest. Making one edge constraint type "not connected" (increasing required tiles) helps, but then some global connectivity tracking algorithm is needed during generation.

## Hexagonal Tiles

Another possibility involves hexagonal tiles, as used in *Infamous* by Sucker Punch (see *Building an Open-World Game Without Hiring an Army* by Nate Fox).

With hexagonal tiles, three edges are constrained and three are free choices during random generation. With non-rotated tiles and only two edge variations per edge type:
- 8 cases, 16 tiles basic
- **64 tiles** for the complete stochastic set

## Herringbone Tiles

For the unfinished 2010 CRPG, the author developed a new variation called *herringbone tiles* to address Wang Tile issues mentioned above.

Herringbone tiles use rectangles with horizontal-to-vertical ratios of **1:2 and 2:1**, with both kinds used in tiling.

### Key Properties

- Rectangle edges touch other rectangle edges consistently
- **6 kinds of "edge matchups"** exist behaving consistently, similar to horizontal and vertical edge types in Wang Tiles
- **Herringbone tiling is isomorphic to hexagonal tiling**: each rectangle can be viewed as a hexagon whose edge lengths remain fixed but whose corners flex

### Tile Counts

Using Cohen-et-al-style tiling with two edge types requires 8 cases (three constrained edges):
- Basic: 16 horizontal + 16 vertical tiles
- **Complete stochastic set: 64 horizontal + 64 vertical = 128 tiles**

These numbers are twice hexagonal tiling size.

### The 128-Tile Dungeon Dataset

The CRPG used 64 horizontal and 64 vertical tiles. Each edge has two possible cases (wide corridor or narrow corridor).

> `chunks.png` — The 128 pre-defined content pieces used to build the dungeon.

> `dungeon_zoomout.png` — An example dungeon generated from this herringbone tile set (zoomed much farther than players would see).

### Positive Aspects

- Although long wall-ish edges exist, they do not appear uniformly (herringbone pattern breaks edges)
- Overall area connectivity is complicated

### The Connectivity Trick

Each tile is conceptualized as two squares with all outward-facing square edges internally connected to the other square's edges; the interior boundary edge between squares may or may not include connections.

> `herringbone_tiling_connectivity.png` — Abstract connectivity with no internal connections.

This guarantees full connectivity (no unreachable content generation), though sometimes requires roundabout paths between points.

### Applicability to City Generation

This technique might benefit applications like Infamous's city; hexagonal tiles poorly matched street grids, which are normally rectangular. Since Herringbone Tiles with rotation appear somewhat isomorphic to hexagonal tiles, they might support approaches involving similar design work and content but yielding rectangular grid streets.

### Colored Corners Note

*Edit 2011-10-24: Won Chun reminds about [Colored corners](http://graphics.cs.kuleuven.be/publications/LD06AWTCECC/), an alternative constraint formulation providing higher quality corner matches for identical content and applicable to herringbone tiles.*
