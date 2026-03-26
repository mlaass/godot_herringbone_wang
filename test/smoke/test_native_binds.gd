extends GutTest


func test_herringbone_generator_class_exists() -> void:
  assert_true(
    ClassDB.class_exists(&"HerringboneGenerator"),
    "HerringboneGenerator should be registered in ClassDB"
  )


func test_herringbone_generator_instantiates() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  assert_not_null(gen, "HerringboneGenerator should instantiate")


func test_generate_abstract_map_is_callable() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  assert_true(
    gen.has_method("generate_abstract_map"),
    "generate_abstract_map method should exist"
  )


func test_generate_abstract_map_returns_array() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  var result: Array = gen.generate_abstract_map(10, 10, 42)
  assert_typeof(result, TYPE_ARRAY, "generate_abstract_map should return Array")
