## Proves the GdUnit4 runner finds and runs a real test (TASK-002).
## A run with no tests prints "No test cases found" and exits 0, which is not a pass.
extends GdUnitTestSuite


func test_engine_version_is_pinned_4_7() -> void:
	var info: Dictionary = Engine.get_version_info()
	assert_int(info["major"]).is_equal(4)
	assert_int(info["minor"]).is_equal(7)


func test_orientation_is_sensor_landscape() -> void:
	var orientation: int = ProjectSettings.get_setting("display/window/handheld/orientation")
	assert_int(orientation).is_equal(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
