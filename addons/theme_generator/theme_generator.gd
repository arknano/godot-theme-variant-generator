@tool
extends RefCounted

signal colors_scanned(unique_colors: Array, color_count: int)
signal theme_generated(path: String)
signal colors_loaded(count: int)
signal error_occurred(message: String)

var unique_colors: Array = []  # { color: Color, original_strings: Array[String] }
var template_path: String = ""
var output_path: String = ""

#region Main Functionality
func scan_template(path: String) -> bool:
	if not FileAccess.file_exists(path):
		error_occurred.emit("File not found: " + path)
		return false

	template_path = path
	var text := FileAccess.get_file_as_string(path)
	_parse_colors(text)

	if unique_colors.is_empty():
		error_occurred.emit("No Color() values found in template.")
		return false

	colors_scanned.emit(unique_colors, unique_colors.size())
	return true


func generate_theme(output: String, color_replacements: Array[Color]) -> bool:
	if not FileAccess.file_exists(template_path):
		error_occurred.emit("Template not found.")
		return false
	if output.is_empty():
		error_occurred.emit("Output path is empty.")
		return false
	if color_replacements.size() != unique_colors.size():
		error_occurred.emit("Color count mismatch.")
		return false

	var text := FileAccess.get_file_as_string(template_path)
	var replacements: Dictionary = {}

	for i in unique_colors.size():
		var new_str := _color_to_tres(color_replacements[i])
		for orig_str: String in (unique_colors[i] as Dictionary)["original_strings"]:
			replacements[orig_str] = new_str

	var result := _apply_replacements(text, replacements)

	var dir := ProjectSettings.globalize_path(output.get_base_dir())
	DirAccess.make_dir_recursive_absolute(dir)

	var file := FileAccess.open(output, FileAccess.WRITE)
	if not file:
		error_occurred.emit("Cannot write to: " + output)
		return false

	file.store_string(result)
	file.close()

	output_path = output
	EditorInterface.get_resource_filesystem().scan()
	theme_generated.emit(output)
	return true


func load_colors_from_theme(theme_path: String) -> Array[Color]:
	if not FileAccess.file_exists(theme_path):
		error_occurred.emit("Theme file not found: " + theme_path)
		return []

	if unique_colors.is_empty():
		error_occurred.emit("Scan template first before loading colors.")
		return []

	var text := FileAccess.get_file_as_string(theme_path)
	var theme_colors := _extract_colors_from_file(text)

	if theme_colors.is_empty():
		error_occurred.emit("No colors found in theme file.")
		return []

	var scanned_keys: PackedStringArray = []
	for entry in unique_colors:
		scanned_keys.append(_color_key((entry as Dictionary)["color"]))

	var replacement_colors: Array[Color] = []
	for key in theme_colors:
		if key not in scanned_keys:
			replacement_colors.append(theme_colors[key])

	if replacement_colors.is_empty():
		error_occurred.emit("No new colors found in theme to apply.")
		return []

	colors_loaded.emit(replacement_colors.size())
	return replacement_colors


#endregion


#region Parsing
func _parse_colors(text: String) -> void:
	unique_colors.clear()

	var regex := RegEx.new()
	regex.compile(r"Color\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)")

	var color_map: Dictionary = {}

	for m in regex.search_all(text):
		var original := m.get_string()
		var c := Color(
			float(m.get_string(1)),
			float(m.get_string(2)),
			float(m.get_string(3)),
			float(m.get_string(4))
		)
		var key := _color_key(c)

		if key not in color_map:
			color_map[key] = {"color": c, "original_strings": []}

		if original not in color_map[key]["original_strings"]:
			color_map[key]["original_strings"].append(original)

	for key in color_map:
		unique_colors.append(color_map[key])


func _extract_colors_from_file(text: String) -> Dictionary:
	var colors: Dictionary = {}
	var regex := RegEx.new()
	regex.compile(r"Color\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)")

	for m in regex.search_all(text):
		var c := Color(
			float(m.get_string(1)),
			float(m.get_string(2)),
			float(m.get_string(3)),
			float(m.get_string(4))
		)
		var key := _color_key(c)
		if key not in colors:
			colors[key] = c

	return colors


#endregion


#region Formatting
func _color_key(c: Color) -> String:
	return (
		"%d_%d_%d_%d"
		% [
			int(round(c.r * 255)),
			int(round(c.g * 255)),
			int(round(c.b * 255)),
			int(round(c.a * 255))
		]
	)


func _apply_replacements(text: String, replacements: Dictionary) -> String:
	if replacements.is_empty():
		return text

	var regex := RegEx.new()
	regex.compile(r"Color\(\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+\s*\)")

	var result := ""
	var last_end := 0

	for m in regex.search_all(text):
		result += text.substr(last_end, m.get_start() - last_end)
		var s := m.get_string()
		result += replacements.get(s, s)
		last_end = m.get_end()
	result += text.substr(last_end)
	return result


func _color_to_tres(c: Color) -> String:
	return (
		"Color(%s, %s, %s, %s)"
		% [
			_format_colour_float(c.r),
			_format_colour_float(c.g),
			_format_colour_float(c.b),
			_format_colour_float(c.a)
		]
	)


func _format_colour_float(f: float) -> String:
	if f == float(int(f)):
		return str(int(f))
	return str(f)



#endregion
