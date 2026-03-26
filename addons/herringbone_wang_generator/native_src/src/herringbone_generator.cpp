#include "herringbone_generator.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void HerringboneGenerator::_bind_methods() {
  ClassDB::bind_method(
      D_METHOD("generate_abstract_map", "width", "height", "seed"),
      &HerringboneGenerator::generate_abstract_map);
}

HerringboneGenerator::HerringboneGenerator() {}

HerringboneGenerator::~HerringboneGenerator() {}

Array HerringboneGenerator::generate_abstract_map(
    int p_width, int p_height, int p_seed) {
  return Array();
}
