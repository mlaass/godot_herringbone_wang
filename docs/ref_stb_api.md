<!-- Source: https://raw.githubusercontent.com/nothings/stb/refs/heads/master/stb_herringbone_wang_tile.h -->
<!-- Fetched: 2026-03-26 -->

# stb_herringbone_wang_tile.h — API Reference

Version 0.7 (2019), Sean Barrett
Public domain / MIT license (dual-licensed)

---

## Purpose

SDK for Herringbone Wang Tile generation. Operates in two modes:
1. **Offline**: Generate tile templates for editing
2. **Runtime**: Load edited tilesets from images and generate procedural maps

The library is purely image/pixel-based — all input and output is RGB pixel data.

## Compilation

```c
// In exactly ONE C/C++ file:
#define STB_HERRINGBONE_WANG_TILE_IMPLEMENTATION
#include "stb_herringbone_wang_tile.h"
```

## Configuration Macros

```c
#define STB_HBWANG_RAND()                    // Custom RNG (default: stb__rand)
#define STB_HBWANG_ASSERT(x)                 // Custom assert
#define STB_HBWANG_STATIC                    // Force static symbols
#define STB_HBWANG_NO_REPITITION_REDUCTION   // Disable repetition limiting
#define STB_HBWANG_MAX_X 100                 // Max width in tiles (default: 100)
#define STB_HBWANG_MAX_Y 100                 // Max height in tiles (default: 100)
```

## Data Structures

### stbhw_tile

```c
typedef struct {
  signed char a, b, c, d, e, f;  // Constraint values (corner or edge colors)
  unsigned char pixels[1];        // Variable-length RGB bitmap data (row-major)
} stbhw_tile;
```

Each tile stores 6 constraint values and its pixel content. For horizontal tiles (2N x N), pixel data is `2N * N * 3` bytes. For vertical tiles (N x 2N), pixel data is `N * 2N * 3` bytes.

### stbhw_tileset

```c
struct stbhw_tileset {
  int is_corner;                  // 1 = corner mode, 0 = edge mode
  int num_color[6];               // Number of colors per constraint type
  int short_side_len;             // N (the short side length in pixels)
  stbhw_tile **h_tiles;           // Array of horizontal tile pointers
  stbhw_tile **v_tiles;           // Array of vertical tile pointers
  int num_h_tiles, max_h_tiles;   // Count and capacity of horizontal tiles
  int num_v_tiles, max_v_tiles;   // Count and capacity of vertical tiles
};
```

### stbhw_config

```c
typedef struct {
  int is_corner;                  // 1 = corner constraints, 0 = edge constraints
  int short_side_len;             // N (short side in pixels, min 1)
  int num_color[6];               // Colors per constraint type
  int num_vary_x;                 // X variation count
  int num_vary_y;                 // Y variation count
  int corner_type_color_template[4][4]; // Corner type color assignments
} stbhw_config;
```

## Constraint Modes

Two mutually exclusive modes:

### Corner mode (`is_corner = 1`)
- Uses 4 corner types with independent color counts
- `num_color[0..3]` = colors per corner type
- `num_color[4..5]` unused
- 4 independent vertex classes in herringbone pattern

### Edge mode (`is_corner = 0`)
- Uses 6 edge types with independent color counts
- `num_color[0..5]` = colors per edge orientation
- 6 distinct edge orientations in herringbone pattern

## Public API Functions

### Error handling

```c
const char *stbhw_get_last_error(void);
```
Returns the last error message string, or NULL.

### Template creation (offline)

```c
void stbhw_get_template_size(stbhw_config *c, int *w, int *h);
```
Compute the required image dimensions for a template.

```c
int stbhw_make_template(stbhw_config *c, unsigned char *data,
                        int w, int h, int stride_in_bytes);
```
Generate a template image with colored borders showing where to paint tiles. Returns 1 on success, 0 on failure.

### Tileset loading (runtime)

```c
int stbhw_build_tileset_from_image(stbhw_tileset *ts,
                                   unsigned char *pixels,
                                   int stride_in_bytes, int w, int h);
```
Parse a template image and extract all tiles with their constraint values. Reads constraint colors from border pixels, copies interior pixels as tile content. Returns 1 on success, 0 on failure.

```c
void stbhw_free_tileset(stbhw_tileset *ts);
```
Free all memory allocated for a tileset.

### Map generation (runtime)

```c
int stbhw_generate_image(stbhw_tileset *ts, int **weighting,
                         unsigned char *pixels,
                         int stride_in_bytes, int w, int h);
```
Generate a herringbone Wang tile map. Output is an RGB image where tile interiors have been copied from the tileset. `weighting` is optional (NULL for uniform). Returns 1 on success, 0 on failure.

## Critical Internal Algorithms

### Tile Selection (`stbhw__choose_tile`)

Two-pass weighted random selection with constraint matching:

```c
static stbhw_tile *stbhw__choose_tile(
    stbhw_tile **list, int numlist,
    signed char *a, signed char *b, signed char *c,
    signed char *d, signed char *e, signed char *f,
    int **weighting)
{
  int i, n, m = 1<<30, pass;
  for (pass = 0; pass < 2; ++pass) {
    n = 0;
    for (i = 0; i < numlist; ++i) {
      stbhw_tile *h = list[i];
      if ((*a < 0 || *a == h->a) &&
          (*b < 0 || *b == h->b) &&
          (*c < 0 || *c == h->c) &&
          (*d < 0 || *d == h->d) &&
          (*e < 0 || *e == h->e) &&
          (*f < 0 || *f == h->f)) {
        n += (weighting ? weighting[0][i] : 1);
        if (n > m) {
          *a = h->a; *b = h->b; *c = h->c;
          *d = h->d; *e = h->e; *f = h->f;
          return h;
        }
      }
    }
    if (n == 0) return NULL;  // No matching tile
    m = STB_HBWANG_RAND() % n;
  }
  return NULL;
}
```

**Pass 1**: Count total weight of matching tiles.
**Pass 2**: Select the m-th matching tile (random selection).

Constraint value of -1 means "unconstrained" (wildcard). After selection, all constraint pointers are updated with the chosen tile's values.

### Herringbone Layout Generation (Corner Mode)

```c
ypos = -1 * sidelen;
for (j = -1; ypos < h; ++j) {
  int phase = (j & 3);       // Row type cycles 0-3
  if (phase == 0) i = 0;
  else i = phase - 4;        // Horizontal offset per phase

  for (;; i += 4) {
    int xpos = i * sidelen;
    if (xpos >= w) break;

    // Place horizontal tile at (xpos, ypos)
    if (xpos + sidelen*2 >= 0 && ypos >= 0) {
      stbhw_tile *t = stbhw__choose_tile(
        ts->h_tiles, ts->num_h_tiles,
        &c_color[j+2][i+2], &c_color[j+2][i+3], &c_color[j+2][i+4],
        &c_color[j+3][i+2], &c_color[j+3][i+3], &c_color[j+3][i+4],
        weighting);
      stbhw__draw_h_tile(output, stride, w, h, xpos, ypos, t, sidelen);
    }

    xpos += sidelen * 3;

    // Place vertical tile at (xpos, ypos)
    if (xpos < w) {
      stbhw_tile *t = stbhw__choose_tile(
        ts->v_tiles, ts->num_v_tiles,
        &c_color[j+2][i+5], &c_color[j+3][i+5], &c_color[j+4][i+5],
        &c_color[j+2][i+6], &c_color[j+3][i+6], &c_color[j+4][i+6],
        weighting);
      stbhw__draw_v_tile(output, stride, w, h, xpos, ypos, t, sidelen);
    }
  }
  ypos += sidelen;
}
```

**Phase-based displacement**: Rows cycle through 4 phases (j & 3), with horizontal offset `phase - 4` for non-zero phases. This creates the characteristic herringbone interlocking pattern.

Each iteration places one horizontal tile (2N x N) followed by one vertical tile (N x 2N), advancing by 4 tile units horizontally.

## Pixel Proxy Encoding Strategy

For the Godot addon, the stb library is used unmodified with a pixel encoding scheme:

- **Tile interiors**: Encode tile ID into RGB pixels (R = type index 0-255, G+B = extra info)
- **Tile borders**: Constraint colors as stb expects
- **Input**: Build synthetic template image with encoded interiors + constraint borders
- **Output**: Decode generated image pixels back to tile IDs via dictionary lookup

stb copies interior pixels verbatim based on constraint matching — it doesn't interpret pixel values, making this encoding transparent to the library.
