class_name GameOptions
extends RefCounted

# Opções de jogo fora do save. O modo de encontros começa em "continuo" (o spawn
# original); "acampamentos" é opt-in e pode ser pedido por, em ordem:
#   1. parâmetro da URL na web: ?encontros=acampamentos
#   2. variável de ambiente ARVEON_ENCOUNTERS=acampamentos
#   3. user://options.cfg  [encounters] mode="acampamentos"
const MODE_CONTINUOUS := "continuo"
const MODE_CAMPS := "acampamentos"
const OPTIONS_PATH := "user://options.cfg"
static var _override := ""

static func set_override(mode: String) -> void:
	_override = mode

static func encounter_mode() -> String:
	if not _override.is_empty():
		return _override
	var raw := ""
	if OS.has_feature("web"):
		raw = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('encontros') || ''", true))
	if raw.is_empty():
		raw = OS.get_environment("ARVEON_ENCOUNTERS")
	if raw.is_empty():
		var file := ConfigFile.new()
		if file.load(OPTIONS_PATH) == OK:
			raw = str(file.get_value("encounters", "mode", ""))
	return MODE_CAMPS if raw.to_lower() in [MODE_CAMPS, "camps"] else MODE_CONTINUOUS

static func save_encounter_mode(mode: String) -> bool:
	var file := ConfigFile.new()
	file.load(OPTIONS_PATH)
	file.set_value("encounters", "mode", mode)
	return file.save(OPTIONS_PATH) == OK
