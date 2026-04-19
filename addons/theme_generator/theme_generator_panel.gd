@tool
extends Control

var _generator: RefCounted
var _color_pickers: Array = []

var _template_edit: LineEdit
var _colors_container: VBoxContainer
var _output_edit: LineEdit
var _generate_button: Button
var _status_label: Label
var _template_file_dialog: EditorFileDialog
var _target_file_dialog: EditorFileDialog


func _ready() -> void:
	custom_minimum_size = Vector2(260, 0)
	var ThemeGeneratorClass = load("res://addons/theme_generator/theme_generator.gd")
	_generator = ThemeGeneratorClass.new()
	_generator.colors_scanned.connect(_on_colors_scanned)
	_generator.theme_generated.connect(_on_theme_generated)
	_generator.colors_loaded.connect(_on_colors_loaded)
	_generator.error_occurred.connect(_on_generator_error)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_ui()


func _build_ui() -> void:
	var vbox := _create_root_container()

	_create_label(vbox, "Theme Variant Generator", 25)
	vbox.add_child(HSeparator.new())

	_build_row_template_picker(vbox)
	_create_button(vbox, "Scan Colours", _on_scan_button, true)
	vbox.add_child(HSeparator.new())

	_build_section_colours(vbox)
	vbox.add_child(HSeparator.new())

	_build_row_target_picker(vbox)
	_build_row_target_buttons(vbox)
	vbox.add_child(HSeparator.new())

	_build_row_status(vbox)


#region UI Construction
func _create_root_container() -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	return vbox


func _build_row_status(parent: VBoxContainer) -> void:
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_status_label)


func _build_row_template_picker(parent: Container) -> void:
	_create_label(parent, "Theme Template File:")

	var template_row := HBoxContainer.new()
	parent.add_child(template_row)

	_template_edit = _create_line_edit(template_row, "res://template.tres")

	_create_button(template_row, "...", _show_template_file_picker)


func _build_section_colours(parent: VBoxContainer) -> void:
	_create_label(parent, "Override Colours:")

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	_colors_container = VBoxContainer.new()
	_colors_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_colors_container.add_theme_constant_override("separation", 4)
	scroll.add_child(_colors_container)


func _build_row_target_picker(parent: VBoxContainer) -> void:
	_create_label(parent, "Target Theme Variant File:")

	var out_row := HBoxContainer.new()
	parent.add_child(out_row)

	_output_edit = _create_line_edit(out_row, "res://variant.tres")

	_create_button(out_row, "...", _show_target_file_picker)


func _build_row_target_buttons(parent: VBoxContainer) -> void:
	var generate_row := HBoxContainer.new()
	parent.add_child(generate_row)

	_generate_button = _create_button(
		generate_row, "Generate Variant", _on_generate_button, true
	)
	_generate_button.disabled = true

	_create_button(generate_row, "Load Colours from Variant", _on_load_colours_button)


#endregion


#region File Picker Dialogs
func _show_template_file_picker() -> void:
	if not _template_file_dialog:
		_template_file_dialog = _build_theme_file_picker(_template_edit, true)
	_show_theme_file_picker(_template_file_dialog, _template_edit)


func _show_target_file_picker() -> void:
	if not _target_file_dialog:
		_target_file_dialog = _build_theme_file_picker(_output_edit, false)
	_show_theme_file_picker(_target_file_dialog, _output_edit)


func _build_theme_file_picker(field: LineEdit, open: bool) -> EditorFileDialog:
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = (
		EditorFileDialog.FILE_MODE_OPEN_FILE if open else EditorFileDialog.FILE_MODE_SAVE_FILE
	)
	file_dialog.filters = PackedStringArray(["*.tres ; Resource Files"])
	file_dialog.file_selected.connect(func(p: String) -> void: field.text = p)
	EditorInterface.get_base_control().add_child(file_dialog)
	return file_dialog


func _show_theme_file_picker(file_dialog: EditorFileDialog, field: LineEdit) -> void:
	file_dialog.current_path = field.text
	file_dialog.popup_centered_ratio(0.7)


#endregion


#region Button Signal Handlers
func _on_scan_button() -> void:
	var path := _template_edit.text.strip_edges()
	_generator.scan_template(path)


func _on_load_colours_button() -> void:
	var path := _output_edit.text.strip_edges()
	var replacements = _generator.load_colors_from_theme(path)
	if not replacements.is_empty():
		for i in _color_pickers.size():
			if i >= replacements.size():
				break
			(_color_pickers[i] as ColorPickerButton).color = replacements[i]


func _on_generate_button() -> void:
	var colors: Array[Color] = []
	for picker in _color_pickers:
		colors.append((picker as ColorPickerButton).color)
	_generator.generate_theme(_output_edit.text.strip_edges(), colors)


#endregion


#region Operation Signal Handlers
func _on_colors_scanned(unique_colors: Array, count: int) -> void:
	_rebuild_color_ui(unique_colors)
	_set_status("Found %d unique colour(s). Set replacements then generate." % count)
	_generate_button.disabled = false


func _on_theme_generated(path: String) -> void:
	_set_status("Saved: " + path)


func _on_colors_loaded(count: int) -> void:
	_set_status("Loaded %d replacement color(s)." % count)


func _on_generator_error(message: String) -> void:
	_set_status(message, true)


#endregion


#region Colour Override UI
func _rebuild_color_ui(unique_colors: Array) -> void:
	for child in _colors_container.get_children():
		child.queue_free()
	_color_pickers.clear()

	for entry: Dictionary in unique_colors:
		var original_color: Color = entry["color"]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_colors_container.add_child(row)

		var orig_rect := ColorRect.new()
		orig_rect.color = original_color
		orig_rect.custom_minimum_size = Vector2(28, 22)
		orig_rect.tooltip_text = _to_hex(original_color)
		row.add_child(orig_rect)

		var arrow := Label.new()
		arrow.text = "→"
		row.add_child(arrow)

		var picker := ColorPickerButton.new()
		picker.color = original_color
		picker.custom_minimum_size = Vector2(72, 22)
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(picker)

		var hex_label := Label.new()
		hex_label.text = _to_hex(original_color)
		hex_label.custom_minimum_size = Vector2(72, 0)
		hex_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(hex_label)
		picker.color_changed.connect(func(c: Color) -> void: hex_label.text = _to_hex(c))

		_color_pickers.append(picker)


func _to_hex(c: Color) -> String:
	return "#" + c.to_html(false).to_upper()


#endregion


func _create_button(
	parent: Container, text: String, callable: Callable, expand: bool = false
) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callable)
	if expand:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button


func _create_label(parent: Container, text: String, size: int = 0) -> Label:
	var label := Label.new()
	if size > 0:  # Can't be bothered get the default font size somehow
		label.add_theme_font_size_override("font_size", size)
	label.text = text
	parent.add_child(label)
	return label


func _create_line_edit(parent: Container, text: String) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text = text
	line_edit.placeholder_text = text
	parent.add_child(line_edit)
	return line_edit


func _set_status(msg: String, is_error: bool = false) -> void:
	_status_label.text = msg
	if is_error:
		_status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		_status_label.remove_theme_color_override("font_color")
