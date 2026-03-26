#ifndef HERRINGBONE_GENERATOR_H
#define HERRINGBONE_GENERATOR_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>

namespace godot {

class HerringboneGenerator : public RefCounted {
  GDCLASS(HerringboneGenerator, RefCounted)

protected:
  static void _bind_methods();

public:
  HerringboneGenerator();
  ~HerringboneGenerator();

  Array generate_abstract_map(int p_width, int p_height, int p_seed);
};

} // namespace godot

#endif
