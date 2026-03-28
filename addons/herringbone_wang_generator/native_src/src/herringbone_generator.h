#ifndef HERRINGBONE_GENERATOR_H
#define HERRINGBONE_GENERATOR_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <vector>
#include <unordered_map>

struct stbhw_tileset;

namespace godot {

class HerringboneGenerator : public RefCounted {
  GDCLASS(HerringboneGenerator, RefCounted)

protected:
  static void _bind_methods();

public:
  HerringboneGenerator();
  ~HerringboneGenerator();

  void set_corner_colors(PackedInt32Array p_colors);
  PackedInt32Array get_corner_colors() const;

  void set_constraint_mode(bool p_is_corner);
  bool get_constraint_mode() const;
  void set_edge_colors(PackedInt32Array p_colors);
  PackedInt32Array get_edge_colors() const;

  void load_tile_definitions(Array p_defs);
  bool build_tileset();
  bool is_ready() const;
  Array generate_abstract_map(int p_width, int p_height, int p_seed);
  String get_last_error() const;

private:
  static const int SIDELEN = 3;
  static const int MAGIC_G = 0x42;
  static const int MAGIC_B = 0x42;
  static const int UNKNOWN_TILE_ID = 255;

  struct TileDef {
    int tile_id;
    int orientation; // 0=H, 1=V
    int constraints[6];
  };

  bool is_corner_ = true;
  int corner_colors_[4] = {2, 2, 2, 2};
  int edge_colors_[6] = {2, 2, 2, 2, 2, 2};
  std::vector<TileDef> tile_defs_;
  stbhw_tileset *tileset_ = nullptr;
  bool ready_ = false;
  String last_error_;

  void free_tileset();
  int find_tile_id(int orientation, int a, int b, int c, int d, int e, int f) const;
};

} // namespace godot

#endif
