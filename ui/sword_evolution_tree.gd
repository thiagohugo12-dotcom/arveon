class_name SwordEvolutionTree
extends VBoxContainer

signal node_selected(kind: String, id: String)

# Visual milestones use actual AbilityRules IDs. Unlocking comes from the rules,
# never from the widget: a locked node can be inspected but not purchased.
const ROWS := [
	[{"kind":"skill1","id":"talho_agil","prof":1,"name":"Talho Ágil"}, {}],
	[{"kind":"normal","id":"corte_crescente","prof":3,"name":"Corte Crescente"}, {"kind":"normal","id":"guarda_reativa","prof":8,"name":"Guarda Reativa"}],
	[{"kind":"passive","id":"fio_afiado","prof":5,"name":"Fio Afiado"}, {"kind":"talent","id":"guarda_aperfeicoada","prof":10,"name":"Guarda Aperfeiçoada"}],
	[{"kind":"talent","id":"sequencia_precisa","prof":10,"name":"Sequência Precisa"}, {"kind":"specialization","id":"escolha","prof":18,"name":"Especialização"}],
	[{"kind":"passive","id":"ritmo_combate","prof":12,"name":"Ritmo de Combate"}, {"kind":"passive","id":"postura_firme","prof":20,"name":"Postura Firme"}],
	[{"kind":"ultimate","id":"danca_laminas","prof":15,"name":"Dança das Lâminas"}, {"kind":"talent","id":"postura_equilibrada","prof":20,"name":"Postura Equilibrada"}],
	[{"kind":"talent","id":"contra_ataque_fatal","prof":20,"name":"Contra-ataque Fatal"}, {}],
	[{"kind":"normal","id":"estocada_precisa","prof":25,"name":"Estocada Precisa"}, {}],
	[{"kind":"mastery","id":"lamina_perfeita","prof":30,"name":"Lâmina Perfeita"}, {}],
	[{"kind":"passive","id":"instinto_veterano","prof":35,"name":"Instinto Veterano"}, {}],
	[{"kind":"normal","id":"ruptura_ancestral","prof":40,"name":"Ruptura Ancestral"}, {}],
	[{"kind":"talent","id":"ritmo_afiado","prof":45,"name":"Ritmo Afiado"}, {"kind":"passive","id":"vontade_ancestral","prof":50,"name":"Vontade Ancestral"}],
	[{}, {"kind":"talent","id":"bastiao_ancestral","prof":55,"name":"Bastião Ancestral"}],
	[{"kind":"supreme","id":"ascensao_lamina","prof":60,"name":"Ascensão da Lâmina"}, {}]
]
const TYPE_TEXT := {"skill1":"Skill 1","normal":"Técnica","passive":"Passiva","ultimate":"Ultimate","talent":"Talento","specialization":"Estilo","mastery":"Maestria","supreme":"Maestria Suprema"}

# These links show the reading order, not additional purchase prerequisites.
# Real talent parents remain in AbilityRules and in each node's detail panel.
class LockMark extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_rect(Rect2(3,0,10,9),DiaryTheme.INK)
		draw_rect(Rect2(5,2,6,5),DiaryTheme.PAPER)
		draw_rect(Rect2(1,7,14,11),DiaryTheme.INK)
		draw_rect(Rect2(3,9,10,7),Color("#dfcca3"))
		draw_rect(Rect2(7,11,2,4),DiaryTheme.INK)

class PathLink extends Control:
	var from_slots: Array = []
	var to_slots: Array = []
	func _init(previous: Array, following: Array) -> void:
		from_slots = previous
		to_slots = following
		custom_minimum_size.y = 24
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var ink := Color("#aa8b53")
		var slots: Array = from_slots+to_slots
		draw_line(Vector2(roundf(size.x*float(slots.min())),12),Vector2(roundf(size.x*float(slots.max())),12),ink,2)
		for slot: float in from_slots:
			var x := roundf(size.x*slot)
			draw_line(Vector2(x,0),Vector2(x,12),ink,2)
		for slot: float in to_slots:
			var x := roundf(size.x*slot)
			draw_line(Vector2(x,12),Vector2(x,24),ink,2)

var progress: GameProgress
var selected_key := "skill1:talho_agil"
var buttons: Dictionary = {}
var states: Dictionary = {}
var cards: Dictionary = {}

func _init(value: GameProgress, selection: String = "skill1:talho_agil") -> void:
	progress = value
	selected_key = selection
	custom_minimum_size.x = 240
	add_theme_constant_override("separation",0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading := DiaryTheme.label("Caminho da Espada",23)
	heading.add_theme_font_override("font",DiaryTheme.heading_font())
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(heading)
	var branches := HBoxContainer.new()
	branches.add_theme_constant_override("separation",12)
	for title: String in ["Ofensivo","Defensivo"]:
		var label := DiaryTheme.label(title,15)
		label.add_theme_font_override("font",DiaryTheme.heading_font())
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branches.add_child(label)
	add_child(branches)
	for row_index in range(ROWS.size()):
		var single := row_index == 0 or row_index == ROWS.size()-1
		if row_index > 0:
			add_child(PathLink.new(_slots(row_index-1),_slots(row_index)))
		if single:
			var center := CenterContainer.new()
			center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			center.add_child(_node_card(ROWS[row_index][0]))
			add_child(center)
		else:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation",12)
			for entry: Dictionary in ROWS[row_index]:
				var center := CenterContainer.new()
				center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				center.custom_minimum_size.x = 110
				if not entry.is_empty(): center.add_child(_node_card(entry))
				row.add_child(center)
			add_child(row)
	var footer := DiaryTheme.label("Linhas: percurso de evolução. Requisitos e efeitos ao tocar.\nVerde: aprendido/equipado · claro: disponível · cadeado: bloqueado.",11)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(footer)

func _slots(row: int) -> Array:
	if row == 0 or row == ROWS.size()-1: return [0.5]
	var result: Array = []
	for column in range(2):
		if not ROWS[row][column].is_empty(): result.append(0.25 if column == 0 else 0.75)
	return result

func _state(entry: Dictionary) -> String:
	var kind: String = entry.kind
	var id: String = entry.id
	if progress.talents.level("espada") < int(entry.prof): return "Bloqueado"
	var loadout: Dictionary = progress.abilities.loadouts.espada
	match kind:
		"skill1": return "Inicial"
		"normal", "ultimate": return "Equipado" if loadout.skills.has(id) else "Disponível"
		"passive": return "Equipado" if loadout.passives.has(id) else "Disponível"
		"mastery", "supreme": return "Automática"
		"specialization": return "Escolhido" if not str(loadout.specialization).is_empty() else "Disponível"
		"talent":
			if progress.abilities.talents.espada.has(id): return "Aprendido"
			var rule := AbilityRules.talent("espada",id)
			if not str(rule.parent).is_empty() and not progress.abilities.talents.espada.has(rule.parent): return "Requer talento"
			return "Disponível" if progress.skill_points() > 0 else "Sem pontos"
	return "Disponível"

func _icon(entry: Dictionary) -> String:
	if entry.kind in ["mastery","supreme","specialization"]: return "maestria"
	if entry.id in ["guarda_reativa","guarda_aperfeicoada","postura_equilibrada","postura_firme","bastiao_ancestral"]: return "Armadura"
	if entry.id == "vontade_ancestral": return "Ervas"
	if entry.kind == "passive": return "Essência"
	return "espada"

func _node_card(entry: Dictionary) -> VBoxContainer:
	var kind: String = entry.kind
	var id: String = entry.id
	var key := kind+":"+id
	var state := _state(entry)
	states[key] = state
	var earned := state in ["Aprendido","Equipado","Automática","Inicial","Escolhido"]
	var blocked := state in ["Bloqueado","Requer talento","Sem pontos"]
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(110,146)
	card.add_theme_constant_override("separation",2)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards[key] = card
	var ribbon := PanelContainer.new()
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_theme_stylebox_override("panel",DiaryTheme.box(DiaryTheme.GREEN if earned else DiaryTheme.WOOD,Color("#c8a86b"),2,1))
	var level := DiaryTheme.label("Prof. %d" % int(entry.prof),12)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.add_theme_color_override("font_color",Color("#fff0ce"))
	ribbon.add_child(level)
	card.add_child(ribbon)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(center)
	var button := Button.new()
	button.name = id
	button.custom_minimum_size = Vector2(60,60)
	button.tooltip_text = "%s · %s\nProficiência %d · %s\nToque para ver requisitos e ações." % [entry.name,TYPE_TEXT[kind],int(entry.prof),state]
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var fill := Color("#d6dfb8") if earned else Color("#e1d1ab") if blocked else Color("#fff0ce")
	var edge := DiaryTheme.GREEN if selected_key == key else Color("#987344")
	button.add_theme_stylebox_override("normal",DiaryTheme.box(fill,edge,0,3 if selected_key == key else 2))
	button.add_theme_stylebox_override("hover",DiaryTheme.box(Color("#fff2ce"),DiaryTheme.GREEN,0,3))
	button.add_theme_stylebox_override("pressed",DiaryTheme.box(Color("#d6dfb8"),DiaryTheme.GREEN,0,3))
	button.add_theme_stylebox_override("focus",DiaryTheme.box(Color.TRANSPARENT,DiaryTheme.GREEN,0,2))
	var icon := PixelItemIcon.new(_icon(entry))
	icon.name = "Icon"
	icon.framed = false
	icon.position = Vector2(6,6)
	icon.size = Vector2(48,48)
	icon.modulate = Color(0.70,0.65,0.53,0.8) if blocked else Color.WHITE
	button.add_child(icon)
	if blocked:
		var lock := LockMark.new()
		lock.name = "Lock"
		lock.position = Vector2(42,39)
		lock.size = Vector2(16,18)
		button.add_child(lock)
	button.pressed.connect(func(): node_selected.emit(kind,id))
	center.add_child(button)
	buttons[key] = button
	var caption := DiaryTheme.label(entry.name,12)
	caption.custom_minimum_size = Vector2(110,32)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(caption)
	var badge := DiaryTheme.label(TYPE_TEXT[kind],10)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(badge)
	var status := DiaryTheme.label(state,10)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color",DiaryTheme.GREEN if earned else DiaryTheme.INK)
	card.add_child(status)
	return card

