extends Control

const MAIN_SCENE := preload("res://scenes/main.tscn")
const BACKDROP: Texture2D = preload("res://assets/loading/arveon-mobile-approved.png")
const SETTINGS_PATH := "user://alpha02_settings.cfg"

var continue_button: Button
var settings_panel: PanelContainer
var confirm_panel: PanelContainer
var audio_button: Button
var muted := false
var touch_buttons: Array[Button] = []
var touch_index := -1
var touch_button: Button
var touch_origin := Vector2.ZERO
var touch_cancelled := false
var starting := false
const TAP_SLOP := 18.0 # Screen pixels, independent of portrait canvas scaling.

func _ready() -> void:
	_load_settings()
	var backdrop := TextureRect.new()
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.055, 0.13, 0.10, 0.63)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", DiaryTheme.piece("frame", 20))
	card.custom_minimum_size = Vector2(290, 0)
	center.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	card.add_child(stack)
	var title := DiaryTheme.label("ARVÉON", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DiaryTheme.heading_font())
	stack.add_child(title)
	var subtitle := DiaryTheme.label("Ascensão Ancestral", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	var version := DiaryTheme.label("ALPHA 0.2 · DOIS ANDARES", 12)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(version)
	stack.add_child(HSeparator.new())
	continue_button = _button("Continuar", stack, func(): _start_game(false))
	_button("Jogar · novo jogo", stack, _request_new_game)
	_button("Configurações", stack, _show_settings)
	var note := DiaryTheme.label("Progresso salvo neste aparelho ou navegador.", 11)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(note)
	settings_panel = _dialog("Configurações")
	var settings_stack := settings_panel.get_child(0) as VBoxContainer
	audio_button = _button("Som: ligado", settings_stack, _toggle_audio)
	_update_audio_button()
	_button("Voltar", settings_stack, _hide_settings)
	settings_panel.hide()
	confirm_panel = _dialog("Começar um novo jogo?")
	var confirm_stack := confirm_panel.get_child(0) as VBoxContainer
	confirm_stack.add_child(DiaryTheme.label("O progresso salvo será substituído. Uma cópia de segurança será mantida.", 13))
	_button("Começar", confirm_stack, func(): _start_game(true))
	_button("Cancelar", confirm_stack, func(): confirm_panel.hide())
	confirm_panel.hide()
	_refresh_save_state()
	_queue_title_report()

func _button(caption: String, parent: Container, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 56)
	DiaryTheme.primary(button)
	button.pressed.connect(action)
	parent.add_child(button)
	touch_buttons.append(button)
	return button

func _input(event: InputEvent) -> void:
	# GUI Controls can consume ScreenTouch before _unhandled_input. Own the
	# entire touch gesture here, before GUI dispatch; native mouse is untouched.
	if starting or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		if event.pressed:
			if touch_index != -1:
				touch_cancelled = true # Multitouch never activates a menu action.
				return
			touch_index = event.index
			touch_origin = get_viewport().get_screen_transform() * event.position
			touch_cancelled = false
			touch_button = _button_at(event)
		elif event.index == touch_index:
			var target := touch_button
			var activate: bool = not event.canceled and not touch_cancelled \
					and _screen_distance(event.position) <= TAP_SLOP \
					and target != null and target == _button_at(event)
			_reset_touch()
			if activate:
				target.pressed.emit()
	elif event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
		if event.index == touch_index and _screen_distance(event.position) > TAP_SLOP:
			touch_cancelled = true

func _button_at(event: InputEventScreenTouch) -> Button:
	for button in touch_buttons:
		if not button.is_visible_in_tree() or button.disabled:
			continue
		# A visible dialog is modal even where its card doesn't cover the title.
		if confirm_panel.visible and not confirm_panel.is_ancestor_of(button):
			continue
		if not confirm_panel.visible and settings_panel.visible and not settings_panel.is_ancestor_of(button):
			continue
		var local := button.make_input_local(event) as InputEventScreenTouch
		if Rect2(Vector2.ZERO, button.size).has_point(local.position):
			return button
	return null

func _screen_distance(position_in_viewport: Vector2) -> float:
	return touch_origin.distance_to(get_viewport().get_screen_transform() * position_in_viewport)

func _reset_touch() -> void:
	touch_index = -1
	touch_button = null
	touch_cancelled = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset_touch()

func _queue_title_report() -> void:
	if DisplayServer.get_name() != "headless" and not RenderingServer.frame_post_draw.is_connected(_report_title_state):
		RenderingServer.frame_post_draw.connect(_report_title_state, CONNECT_ONE_SHOT)

func _report_title_state() -> void:
	# Read-only diagnostics after layout/render, never an input test hook.
	if starting or is_queued_for_deletion():
		return
	var buttons: Array = []
	for button in touch_buttons:
		if button.is_visible_in_tree():
			var center := button.get_global_transform_with_canvas() * (button.size * 0.5)
			buttons.append({"text": button.text, "x": center.x, "y": center.y, "disabled": button.disabled})
	var viewport_size := get_viewport_rect().size
	print("ARVEON_TITLE_STATE " + JSON.stringify({"settings": settings_panel.visible, "confirm": confirm_panel.visible, "buttons": buttons, "viewport": [viewport_size.x, viewport_size.y]}))

func _dialog(caption: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DiaryTheme.piece("paper", 18))
	panel.custom_minimum_size = Vector2(290, 0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	panel.add_child(stack)
	var heading := DiaryTheme.label(caption, 22)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", DiaryTheme.heading_font())
	stack.add_child(heading)
	panel.resized.connect(func(): panel.position = (size - panel.size) * 0.5)
	return panel

func _refresh_save_state() -> void:
	var probe := GameProgress.new()
	var test_save := OS.get_environment("ARVEON_SAVE_PATH")
	if test_save.is_empty():
		test_save = OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	if not test_save.is_empty():
		probe.save_path = test_save
	continue_button.disabled = not probe.load_save()

func _request_new_game() -> void:
	if continue_button.disabled:
		_start_game(true)
	else:
		confirm_panel.show()

func _show_settings() -> void:
	settings_panel.show()
	_queue_title_report()

func _hide_settings() -> void:
	settings_panel.hide()
	_queue_title_report()

func _toggle_audio() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	_update_audio_button()
	_queue_title_report()
	var settings := ConfigFile.new()
	settings.set_value("audio", "muted", muted)
	settings.save(SETTINGS_PATH)
	if OS.has_feature("web"):
		JavaScriptBridge.force_fs_sync()

func _update_audio_button() -> void:
	if audio_button != null:
		audio_button.text = "Som: desligado" if muted else "Som: ligado"

func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		muted = bool(settings.get_value("audio", "muted", false))
	AudioServer.set_bus_mute(0, muted)

func _start_game(fresh: bool) -> void:
	if starting:
		return
	starting = true
	_reset_touch()
	var game := MAIN_SCENE.instantiate()
	game.launch_new_game = fresh
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	print("ARVEON_TITLE_STARTED " + JSON.stringify({"floor": game.progress.ascension.current_floor, "player": game.player != null}))
	queue_free()
