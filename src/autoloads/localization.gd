extends Node

# ---------------------------------------------------------------------------
# Localization — 本地化系统单例
# 依赖：SaveLoad（读取语言设置）
# GDD：localization.md
# ---------------------------------------------------------------------------

const SUPPORTED_LANGUAGES := ["zh-CN", "en-US"]
const DEFAULT_LANGUAGE := "zh-CN"
const LOCALIZATION_DIR := "res://assets/localization/"

var _strings: Dictionary = {}
var _current_language: String = DEFAULT_LANGUAGE


func _ready() -> void:
	var settings: Dictionary = SaveLoad.get_value("settings", {})
	var lang: String = settings.get("language_code", DEFAULT_LANGUAGE)
	load_language(lang)


func load_language(language_code: String) -> void:
	if language_code not in SUPPORTED_LANGUAGES:
		language_code = DEFAULT_LANGUAGE
	_current_language = language_code
	var path := LOCALIZATION_DIR + language_code + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Localization: cannot open %s" % path)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("Localization: JSON parse error in %s" % path)
		return
	_strings = json.data


# 获取本地化字符串，支持 {0}{1} 占位符替换
func L(key: String, args: Array = []) -> String:
	var text: String = _strings.get(key, "")
	if text.is_empty():
		# 回退到默认语言
		if _current_language != DEFAULT_LANGUAGE:
			text = _strings.get(key, key)
		else:
			text = key
	for i in args.size():
		text = text.replace("{%d}" % i, str(args[i]))
	return text


func get_current_language() -> String:
	return _current_language
