class_name SwordEvolutionTree
extends VBoxContainer

signal node_selected(kind: String, id: String)

# Visual milestones use actual AbilityRules IDs. Unlocking comes from the rules,
# never from the widget: a locked node can be inspected but not purchased.
const ROWS := [
	[{"kind":"skill1","id":"talho_agil","prof":1,"name":"Talho Ágil"}, {}],
	[{"kind":"normal","id":"corte_crescente","prof":3,"name":"Corte Crescente"}, {"kind":"passive","id":"fio_afiado","prof":5,"name":"Fio Afiado"}],
	[{"kind":"talent","id":"sequencia_precisa","prof":10,"name":"Sequência Precisa"}, {"kind":"normal","id":"guarda_reativa","prof":8,"name":"Guarda Reativa"}],
	[{"kind":"passive","id":"ritmo_combate","prof":12,"name":"Ritmo de Combate"}, {"kind":"talent","id":"guarda_aperfeicoada","prof":10,"name":"Guarda Aperfeiçoada"}],
	[{"kind":"ultimate","id":"danca_laminas","prof":15,"name":"Dança das Lâminas"}, {"kind":"specialization","id":"escolha","prof":18,"name":"Especialização"}],
	[{"kind":"talent","id":"contra_ataque_fatal","prof":20,"name":"Contra-ataque Fatal"}, {"kind":"talent","id":"postura_equilibrada","prof":20,"name":"Postura Equilibrada"}],
	[{"kind":"normal","id":"estocada_precisa","prof":25,"name":"Estocada Precisa"}, {"kind":"passive","id":"postura_firme","prof":20,"name":"Postura Firme"}],
	[{"kind":"mastery","id":"lamina_perfeita","prof":30,"name":"Lâmina Perfeita"}, {"kind":"passive","id":"instinto_veterano","prof":35,"name":"Instinto Veterano"}],
	[{"kind":"normal","id":"ruptura_ancestral","prof":40,"name":"Ruptura Ancestral"}, {"kind":"talent","id":"ritmo_afiado","prof":45,"name":"Ritmo Afiado"}],
	[{"kind":"passive","id":"vontade_ancestral","prof":50,"name":"Vontade Ancestral"}, {"kind":"talent","id":"bastiao_ancestral","prof":55,"name":"Bastião Ancestral"}],
	[{"kind":"supreme","id":"ascensao_lamina","prof":60,"name":"Ascensão da Lâmina"}, {}]
]
const TYPE_TEXT := {"skill1":"Skill 1","normal":"Técnica","passive":"Passiva","ultimate":"Ultimate","talent":"Talento","specialization":"Estilo","mastery":"Maestria","supreme":"Maestria Suprema"}

var progress: GameProgress
var selected_key := "skill1:talho_agil"
var buttons: Dictionary = {}

func _init(value: GameProgress, selection: String = "skill1:talho_agil") -> void:
	progress = value
	selected_key = selection
	add_theme_constant_override("separation",3)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading := DiaryTheme.label("CAMINHO DA ESPADA  ·  PROFICIÊNCIA 1–60",16)
	heading.add_theme_font_override("font",DiaryTheme.heading_font())
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(heading)
	var legend := DiaryTheme.label("À esquerda: técnicas e ofensiva    ·    À direita: guardas e passivas",11)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(legend)
	for row_index in range(ROWS.size()):
		if row_index > 0:
			var connection := DiaryTheme.label("◆              ◆",12)
			connection.add_theme_color_override("font_color",DiaryTheme.WOOD)
			connection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(connection)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",5)
		add_child(row)
		for entry: Dictionary in ROWS[row_index]:
			if entry.is_empty():
				var blank := Control.new()
				blank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(blank)
				continue
			var kind: String = entry.kind
			var id: String = entry.id
			var key := kind+":"+id
			var required: int = entry.prof
			var unlocked := progress.talents.level("espada") >= required
			var button := Button.new()
			button.text = "Prof. %d · %s\n%s" % [required,TYPE_TEXT[kind],entry.name]
			button.tooltip_text = "%s · requer proficiência %d%s" % [entry.name,required," · desbloqueado" if unlocked else " · bloqueado"]
			button.add_theme_font_size_override("font_size",12)
			button.custom_minimum_size = Vector2(116,66)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			var fill := Color("#e7f0d1") if unlocked else Color("#e5d5b1")
			var edge := DiaryTheme.GREEN if selected_key == key else Color("#b29160")
			button.add_theme_stylebox_override("normal",DiaryTheme.box(fill,edge,5,3 if selected_key == key else 1))
			button.add_theme_stylebox_override("hover",DiaryTheme.box(Color("#f9eac8"),DiaryTheme.GREEN,5,2))
			button.add_theme_color_override("font_color",DiaryTheme.INK)
			button.add_theme_color_override("font_hover_color",DiaryTheme.INK)
			button.add_theme_color_override("font_focus_color",DiaryTheme.INK)
			button.pressed.connect(func(): node_selected.emit(kind,id))
			row.add_child(button)
			buttons[key] = button
	var footer := DiaryTheme.label("Verde: desbloqueado · bege: ainda bloqueado · toque para ver requisitos e opções.",11)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(footer)
