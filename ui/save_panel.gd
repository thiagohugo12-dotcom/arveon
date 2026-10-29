class_name SavePanel
extends PanelContainer

signal action_requested(action: String)
var description: Label
var export_button: Button
var import_button: Button
var confirm_button: Button
var cancel_button: Button
var close_button: Button

func _ready() -> void:
	z_index = 12
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Registro do Aventureiro"
	title.add_theme_font_size_override("font_size", 17)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.custom_minimum_size.x = 220
	scroll.add_child(description)
	export_button = _button(column, "Exportar save", "export")
	import_button = _button(column, "Importar save", "import")
	confirm_button = _button(column, "Substituir meu progresso", "confirm")
	cancel_button = _button(column, "Cancelar importação", "cancel")
	close_button = _button(column, "Fechar", "close")

func _button(column: VBoxContainer, caption: String, action: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 44
	button.pressed.connect(func(): action_requested.emit(action))
	column.add_child(button)
	return button

func open(progress: GameProgress) -> void:
	show()
	confirmation(false)
	description.text = "%s\nNível %d · XP %d · Ouro %d\n%s\nBackup só neste dispositivo/navegador. Guarde um arquivo antes de limpar os dados." % [progress.save_status if not progress.save_status.is_empty() else "Salvamento automático local", progress.level(), progress.xp, progress.gold, progress.ascension.summary()]

func preview(progress: GameProgress) -> void:
	confirmation(true)
	description.text = "Arquivo validado. Nível %d · XP %d · Ouro %d\n%s\nSubstituir encerra a tentativa da Torre e retorna à Mata. O save atual será preservado em uma cópia local. Confirma?" % [progress.level(), progress.xp, progress.gold, progress.ascension.summary()]

	if not progress.save_status.is_empty():
		description.text += "\n" + progress.save_status

func confirmation(pending: bool) -> void:
	export_button.visible = not pending
	import_button.visible = not pending
	confirm_button.visible = pending
	cancel_button.visible = pending
