#include "herringbone_generator.h"
#include "stb_herringbone_wang_impl.h"
#include "stb_herringbone_wang_tile.h"
#include <godot_cpp/core/class_db.hpp>
#include <cstring>

using namespace godot;

void HerringboneGenerator::_bind_methods() {
  ClassDB::bind_method(
      D_METHOD("set_corner_colors", "colors"),
      &HerringboneGenerator::set_corner_colors);
  ClassDB::bind_method(
      D_METHOD("get_corner_colors"),
      &HerringboneGenerator::get_corner_colors);
  ClassDB::bind_method(
      D_METHOD("load_tile_definitions", "definitions"),
      &HerringboneGenerator::load_tile_definitions);
  ClassDB::bind_method(
      D_METHOD("build_tileset"),
      &HerringboneGenerator::build_tileset);
  ClassDB::bind_method(
      D_METHOD("is_ready"),
      &HerringboneGenerator::is_ready);
  ClassDB::bind_method(
      D_METHOD("generate_abstract_map", "width", "height", "seed"),
      &HerringboneGenerator::generate_abstract_map);
  ClassDB::bind_method(
      D_METHOD("get_last_error"),
      &HerringboneGenerator::get_last_error);
}

HerringboneGenerator::HerringboneGenerator() {}

HerringboneGenerator::~HerringboneGenerator() {
  free_tileset();
}

void HerringboneGenerator::set_corner_colors(PackedInt32Array p_colors) {
  if (p_colors.size() != 4) {
    last_error_ = "corner_colors must have exactly 4 elements";
    return;
  }
  for (int i = 0; i < 4; ++i) {
    int c = p_colors[i];
    if (c < 1 || c > 4) {
      last_error_ = "corner colors must be between 1 and 4";
      return;
    }
    corner_colors_[i] = c;
  }
  ready_ = false;
}

PackedInt32Array HerringboneGenerator::get_corner_colors() const {
  PackedInt32Array result;
  result.resize(4);
  for (int i = 0; i < 4; ++i) {
    result[i] = corner_colors_[i];
  }
  return result;
}

void HerringboneGenerator::load_tile_definitions(Array p_defs) {
  tile_defs_.clear();
  tile_defs_.reserve(p_defs.size());

  for (int i = 0; i < p_defs.size(); ++i) {
    Dictionary d = p_defs[i];
    TileDef def;
    def.tile_id = d.get("tile_id", 0);
    def.orientation = d.get("orientation", 0);
    PackedInt32Array cons = d.get("constraints", PackedInt32Array());
    if (cons.size() != 6) {
      last_error_ = "each tile definition must have 6 constraints";
      tile_defs_.clear();
      return;
    }
    for (int j = 0; j < 6; ++j) {
      def.constraints[j] = cons[j];
    }
    tile_defs_.push_back(def);
  }
  ready_ = false;
}

bool HerringboneGenerator::build_tileset() {
  free_tileset();
  ready_ = false;

  // Create stb config
  stbhw_config config;
  memset(&config, 0, sizeof(config));
  config.is_corner = 1;
  config.short_side_len = SIDELEN;
  config.num_vary_x = 1;
  config.num_vary_y = 1;
  for (int i = 0; i < 4; ++i) {
    config.num_color[i] = corner_colors_[i];
  }

  // Get template size
  int tw = 0, th = 0;
  stbhw_get_template_size(&config, &tw, &th);
  if (tw <= 0 || th <= 0) {
    last_error_ = "failed to compute template size";
    return false;
  }

  // Create template image
  int stride = tw * 3;
  std::vector<unsigned char> template_data(stride * th, 0);
  if (!stbhw_make_template(&config, template_data.data(), tw, th, stride)) {
    const char *err = stbhw_get_last_error();
    last_error_ = err ? err : "stbhw_make_template failed";
    return false;
  }

  // Parse template into tileset
  tileset_ = new stbhw_tileset();
  memset(tileset_, 0, sizeof(stbhw_tileset));
  if (!stbhw_build_tileset_from_image(
          tileset_, template_data.data(), stride, tw, th)) {
    const char *err = stbhw_get_last_error();
    last_error_ = err ? err : "stbhw_build_tileset_from_image failed";
    delete tileset_;
    tileset_ = nullptr;
    return false;
  }

  // Paint tile pixels with tile_id encoding (pixel proxy)
  // For each tile in the tileset, find the matching definition
  // and overwrite all interior pixels with R=tile_id, G=MAGIC, B=MAGIC
  int sl = tileset_->short_side_len;

  for (int i = 0; i < tileset_->num_h_tiles; ++i) {
    stbhw_tile *t = tileset_->h_tiles[i];
    int tid = find_tile_id(0, t->a, t->b, t->c, t->d, t->e, t->f);
    int pw = sl * 2;
    int ph = sl;
    for (int y = 0; y < ph; ++y) {
      for (int x = 0; x < pw; ++x) {
        int idx = (y * pw + x) * 3;
        t->pixels[idx + 0] = (unsigned char)tid;
        t->pixels[idx + 1] = MAGIC_G;
        t->pixels[idx + 2] = MAGIC_B;
      }
    }
  }

  for (int i = 0; i < tileset_->num_v_tiles; ++i) {
    stbhw_tile *t = tileset_->v_tiles[i];
    int tid = find_tile_id(1, t->a, t->b, t->c, t->d, t->e, t->f);
    int pw = sl;
    int ph = sl * 2;
    for (int y = 0; y < ph; ++y) {
      for (int x = 0; x < pw; ++x) {
        int idx = (y * pw + x) * 3;
        t->pixels[idx + 0] = (unsigned char)tid;
        t->pixels[idx + 1] = MAGIC_G;
        t->pixels[idx + 2] = MAGIC_B;
      }
    }
  }

  ready_ = true;
  return true;
}

bool HerringboneGenerator::is_ready() const {
  return ready_;
}

Array HerringboneGenerator::generate_abstract_map(
    int p_width, int p_height, int p_seed) {
  Array result;

  if (!ready_ || tileset_ == nullptr) {
    last_error_ = "tileset not built; call build_tileset() first";
    return result;
  }

  int sl = tileset_->short_side_len;
  int out_w = p_width * sl;
  int out_h = p_height * sl;

  if (out_w <= 0 || out_h <= 0) {
    last_error_ = "invalid map dimensions";
    return result;
  }

  // Seed and generate pixel output
  herringbone_seed_rng((unsigned int)p_seed);

  int stride = out_w * 3;
  std::vector<unsigned char> output(stride * out_h, 0);

  if (!stbhw_generate_image(
          tileset_, nullptr, output.data(), stride, out_w, out_h)) {
    const char *err = stbhw_get_last_error();
    last_error_ = err ? err : "stbhw_generate_image failed";
    return result;
  }

  // Walk the herringbone layout to extract tile placements
  // This replicates the layout loop from stbhw_generate_image
  int ypos = -1 * sl;
  for (int j = -1; ypos < out_h; ++j) {
    int phase = j & 3;
    int i_start;
    if (phase == 0) {
      i_start = 0;
    } else {
      i_start = phase - 4;
    }

    for (int i = i_start;; i += 4) {
      int xpos = i * sl;
      if (xpos >= out_w)
        break;

      // Horizontal tile at (xpos, ypos), size 2*sl x sl
      if (xpos + sl * 2 >= 0 && ypos >= 0) {
        int sx = xpos + sl;       // sample x (center)
        int sy = ypos + sl / 2;   // sample y (center)
        if (sx >= 0 && sx < out_w && sy >= 0 && sy < out_h) {
          int pidx = sy * stride + sx * 3;
          if (output[pidx + 1] == MAGIC_G && output[pidx + 2] == MAGIC_B) {
            Dictionary entry;
            entry["tile_id"] = (int)output[pidx];
            entry["orientation"] = 0;
            entry["grid_x"] = i;
            entry["grid_y"] = j;
            result.push_back(entry);
          }
        }
      }

      int vxpos = (i + 3) * sl;

      // Vertical tile at (vxpos, ypos), size sl x 2*sl
      if (vxpos < out_w) {
        int sx = vxpos + sl / 2;  // sample x (center)
        int sy = ypos + sl;       // sample y (center)
        if (sx >= 0 && sx < out_w && sy >= 0 && sy < out_h) {
          int pidx = sy * stride + sx * 3;
          if (output[pidx + 1] == MAGIC_G && output[pidx + 2] == MAGIC_B) {
            Dictionary entry;
            entry["tile_id"] = (int)output[pidx];
            entry["orientation"] = 1;
            entry["grid_x"] = i + 3;
            entry["grid_y"] = j;
            result.push_back(entry);
          }
        }
      }
    }
    ypos += sl;
  }

  return result;
}

String HerringboneGenerator::get_last_error() const {
  return last_error_;
}

void HerringboneGenerator::free_tileset() {
  if (tileset_ != nullptr) {
    stbhw_free_tileset(tileset_);
    delete tileset_;
    tileset_ = nullptr;
  }
  ready_ = false;
}

int HerringboneGenerator::find_tile_id(
    int orientation,
    int a, int b, int c, int d, int e, int f) const {
  for (const auto &def : tile_defs_) {
    if (def.orientation == orientation &&
        def.constraints[0] == a && def.constraints[1] == b &&
        def.constraints[2] == c && def.constraints[3] == d &&
        def.constraints[4] == e && def.constraints[5] == f) {
      return def.tile_id;
    }
  }
  return UNKNOWN_TILE_ID;
}
