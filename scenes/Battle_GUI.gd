extends CanvasLayer

signal command_send(command_name)
signal building_target_selected(construction_type)

var start_texture = preload("res://assets/images/play-button.png")
var pause_texture = preload("res://assets/images/pause-button.png")
var is_play_button_pressed = false

onready var selection_preview_button = $MainInfoBox/SelectionPreview/Button
onready var selection_preview_image = $MainInfoBox/SelectionPreview/Button/Sprite

func _ready():
    self.set_process(false)
    self._update_start_pause_button()
    selection_preview_button.connect("button_up", self, "_on_gui_event", [ "selection_preview_clicked" ])
    $ResetGameButton.connect("button_up", self, "_on_gui_event", [ "reset_game_clicked" ])
    $LoadGameButton.connect("button_up", self, "_on_gui_event", [ "load_game_clicked" ])
    $MainInfoBox/StartWaveButton.connect("button_up", self, "_on_gui_event", [ "start_wave_clicked" ])

    $MainInfoBox/BuildingMenuButton.connect("button_up", self, "_on_BuildingMenuButton_pressed")
    $BuildingMenu.connect("building_target_selected", self, "_on_building_menu_event")
    $MainInfoBox/SettingsMenuButton.connect("button_up", self, "_on_setting_button_click")

    $SettingsMenu/SaveGameButton.connect("button_up", self, "_on_gui_event", [ "save_game_clicked" ])
    $SettingsMenu/ExitGameButton.connect("button_up", self, "_on_gui_event", [ "exit_game_clicked" ])
    $GameOverMenu/ExitGameButton.connect("button_up", self, "_on_gui_event", [ "exit_game_clicked" ])

func show_game_over_menu():
    $GameOverMenu.show()

func set_preview_image(sprite, scale: Vector2, region_rect: Rect2) -> void:
    selection_preview_image.set_scale(scale)
    selection_preview_image.texture = sprite
    selection_preview_image.set_region_rect(region_rect)

func set_preview_image_visibility(visible: bool) -> void:
    $MainInfoBox/SelectionPreview/Button/Sprite.visible = visible

func set_notification_visibility(visible: bool) -> void:
    $Notifications.visible = visible

func set_notification_text(text: String) -> void:
    $Notifications/Label.text = text

func update_currency_bar(type: String, value: int) -> void:
    var text_value = "%d" % value
    if type == "ruby":
        $MainInfoBox/CurrencyBar/Ruby/Label.text = text_value
    if type == "sapphire":
        $MainInfoBox/CurrencyBar/Sapphire/Label.text = text_value
    if type == "topaz":
        $MainInfoBox/CurrencyBar/Topaz/Label.text = text_value

func set_upgrading_menu_visibility(visible: bool = false) -> void:
    $UpgradingMenu.visible = visible

func set_upgrading_menu_target(construction: Area2D, game_data: Node) -> void:
    $UpgradingMenu.set_target_construction(construction, game_data)

func _on_gui_event(event_name: String) -> void:
    if event_name == "start_wave_clicked":
        self._update_start_pause_button()

    emit_signal("command_send", event_name)

func _on_building_menu_event(construction_type: int) -> void:
    emit_signal("building_target_selected", construction_type)

func _on_BuildingMenu_close_menu():
    $BuildingMenu.hide()

func _on_BuildingMenuButton_pressed():
    if not $BuildingMenu.visible:
        $BuildingMenu.show()
    else:
        $BuildingMenu.hide()

func _on_setting_button_click():
    if not $SettingsMenu.visible:
        $SettingsMenu.show()
    else:
        $SettingsMenu.hide()

func _update_start_pause_button():
    if is_play_button_pressed:
        $MainInfoBox/StartWaveButton.texture_normal = pause_texture
    else:
        $MainInfoBox/StartWaveButton.texture_normal = start_texture
    is_play_button_pressed = not is_play_button_pressed

