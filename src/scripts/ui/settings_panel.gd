extends CanvasLayer

# ---------------------------------------------------------------------------
# SettingsPanel — 设置面板
# 允许调整 BGM/SFX 音量，以及切换语言
# ---------------------------------------------------------------------------

var _bgm_slider: HSlider
var _sfx_slider: HSlider
var _lang_option: OptionButton

func _ready() -> void:
	layer = 100
	_build_ui()
	_load_current_settings()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchor_and_offset(SIDE_LEFT,   0.30, 0.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.70, 0.0)
	panel.set_anchor_and_offset(SIDE_TOP,    0.25, 0.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0.75, 0.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = Localization.L("ui.settings")
	if title.text == "ui.settings":
		title.text = "设置 / Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	# BGM Volume
	var bgm_hbox := HBoxContainer.new()
	bgm_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bgm_hbox)
	
	var bgm_lbl := Label.new()
	bgm_lbl.text = "BGM " + Localization.L("ui.volume")
	if bgm_lbl.text == "BGM ui.volume": bgm_lbl.text = "BGM 音量"
	bgm_lbl.custom_minimum_size = Vector2(100, 0)
	bgm_hbox.add_child(bgm_lbl)
	
	_bgm_slider = HSlider.new()
	_bgm_slider.custom_minimum_size = Vector2(200, 30)
	_bgm_slider.min_value = 0
	_bgm_slider.max_value = 100
	_bgm_slider.step = 5
	_bgm_slider.value_changed.connect(_on_bgm_changed)
	bgm_hbox.add_child(_bgm_slider)

	# SFX Volume
	var sfx_hbox := HBoxContainer.new()
	sfx_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(sfx_hbox)
	
	var sfx_lbl := Label.new()
	sfx_lbl.text = "SFX " + Localization.L("ui.volume")
	if sfx_lbl.text == "SFX ui.volume": sfx_lbl.text = "SFX 音量"
	sfx_lbl.custom_minimum_size = Vector2(100, 0)
	sfx_hbox.add_child(sfx_lbl)
	
	_sfx_slider = HSlider.new()
	_sfx_slider.custom_minimum_size = Vector2(200, 30)
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.step = 5
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	sfx_hbox.add_child(_sfx_slider)

	# Language
	var lang_hbox := HBoxContainer.new()
	lang_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(lang_hbox)
	
	var lang_lbl := Label.new()
	lang_lbl.text = Localization.L("ui.language")
	if lang_lbl.text == "ui.language": lang_lbl.text = "语言 / Language"
	lang_lbl.custom_minimum_size = Vector2(140, 0)
	lang_hbox.add_child(lang_lbl)
	
	_lang_option = OptionButton.new()
	_lang_option.custom_minimum_size = Vector2(160, 30)
	_lang_option.add_item("简体中文", 0)
	_lang_option.set_item_metadata(0, "zh-CN")
	_lang_option.add_item("English", 1)
	_lang_option.set_item_metadata(1, "en-US")
	_lang_option.item_selected.connect(_on_language_selected)
	lang_hbox.add_child(_lang_option)
	
	var hint := Label.new()
	hint.text = "(* 重启游戏后生效 / Requires Restart *)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint)

	# Close Button
	var btn_close := Button.new()
	btn_close.text = Localization.L("ui.close")
	if btn_close.text == "ui.close": btn_close.text = "关闭 / Close"
	btn_close.custom_minimum_size = Vector2(160, 48)
	btn_close.add_theme_font_size_override("font_size", 18)
	btn_close.pressed.connect(_on_close)
	vbox.add_child(btn_close)


func _load_current_settings() -> void:
	var settings: Dictionary = SaveLoad.get_value("settings", {})
	var audio: Dictionary = settings.get("audio", {})
	_bgm_slider.value = audio.get("bgm_volume", 60)
	_sfx_slider.value = audio.get("sfx_volume", 80)
	
	var lang: String = settings.get("language_code", "zh-CN")
	for i in _lang_option.item_count:
		if _lang_option.get_item_metadata(i) == lang:
			_lang_option.select(i)
			break


func _on_bgm_changed(val: float) -> void:
	AudioSystem.set_bgm_volume(val)


func _on_sfx_changed(val: float) -> void:
	AudioSystem.set_sfx_volume(val)


func _on_language_selected(idx: int) -> void:
	var lang_code: String = _lang_option.get_item_metadata(idx)
	var settings: Dictionary = SaveLoad.get_value("settings", {})
	settings["language_code"] = lang_code
	SaveLoad.set_value("settings", settings)
	SaveLoad.save_game()


func _on_close() -> void:
	queue_free()
