class_name BrowserSave
extends RefCounted

var api: JavaScriptObject
var hidden_callback: JavaScriptObject
var import_callback: JavaScriptObject
var detach_callback: JavaScriptObject

func initialize() -> void:
	if api != null or not OS.has_feature("web"):
		return
	if JavaScriptBridge.get_interface("GrandeArvoreSave") == null:
		JavaScriptBridge.eval(FileAccess.get_file_as_string("res://scripts/platform/browser_save.js"), true)
	api = JavaScriptBridge.get_interface("GrandeArvoreSave")

func read() -> String:
	initialize()
	return str(api.read()) if api != null else ""

func write(text: String, replace: bool = false) -> String:
	initialize()
	return str(api.write(text, replace)) if api != null else "storage"

func available() -> bool:
	return api != null and api.available()

func watch_hidden(callback: Callable) -> void:
	initialize()
	if api != null:
		hidden_callback = JavaScriptBridge.create_callback(func(_args: Array): callback.call())
		detach_callback = api.onHidden(hidden_callback)

func pick(callback: Callable) -> void:
	initialize()
	if api != null:
		import_callback = JavaScriptBridge.create_callback(func(args: Array): callback.call(str(args[0]) if not args.is_empty() else ""))
		api.pick(import_callback)

func detach() -> void:
	if detach_callback != null:
		detach_callback.call("call")
		detach_callback = null
