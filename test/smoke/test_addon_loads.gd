extends GutTest


func test_gdextension_file_exists() -> void:
  var path: String = "res://addons/herringbone_wang_generator/herringbone_native.gdextension"
  assert_true(FileAccess.file_exists(path), ".gdextension file should exist")


func test_native_library_exists() -> void:
  var dir: DirAccess = DirAccess.open(
    "res://addons/herringbone_wang_generator/"
  )
  assert_not_null(dir, "addon directory should be accessible")
  var found_so: bool = false
  if dir:
    dir.list_dir_begin()
    var file_name: String = dir.get_next()
    while file_name != "":
      if file_name.ends_with(".so") or file_name.ends_with(".dll"):
        found_so = true
        break
      file_name = dir.get_next()
    dir.list_dir_end()
  assert_true(found_so, "native library (.so or .dll) should exist")
