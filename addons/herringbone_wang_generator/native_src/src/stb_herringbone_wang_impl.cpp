#include "stb_herringbone_wang_impl.h"
#include <cassert>

static unsigned int s_rng_state = 1;

void herringbone_seed_rng(unsigned int seed) {
  s_rng_state = seed ? seed : 1;
}

static int herringbone_rng() {
  // xorshift32
  s_rng_state ^= s_rng_state << 13;
  s_rng_state ^= s_rng_state >> 17;
  s_rng_state ^= s_rng_state << 5;
  return (int)(s_rng_state >> 4);
}

#define STB_HBWANG_RAND() herringbone_rng()
#define STB_HBWANG_MAX_X 1000
#define STB_HBWANG_MAX_Y 1000
#define STB_HBWANG_ASSERT(x) ((void)(x))
#define STB_HERRINGBONE_WANG_TILE_IMPLEMENTATION
#include "stb_herringbone_wang_tile.h"
