extends CanvasLayer

signal command_send(command_name)
signal building_target_selected(construction_type)

var start_texture = preload("res://assets/images/play-button.png")
var pause_texture = preload("res://assets/images/pause-button.png")
var is_play_button_pressed = false

onready var selectionPreviewButton = $SelectionPreview/Button

func _ready():
    self.set_process(false)
    self._update_start_pause_button()
    selectionPreviewButton.connect("button_up", self, "_on_gui_event", [ "selection_preview_clicked" ])
    $ResetGameButton.connect("button_up", self, "_on_gui_event", [ "reset_game_clicked" ])
    $LoadGameButton.connect("button_up", self, "_on_gui_event", [ "load_game_clicked" ])
    $StartWaveButton.connect("button_up", self, "_on_gui_event", [ "start_wave_clicked" ])

    $BuildingMenuButton.connect("button_up", self, "_on_BuildingMenuButton_pressed")
    $BuildingMenu.connect("building_target_selected", self, "_on_building_menu_event")
    $SettingsMenuButton.connect("button_up", self, "_on_setting_button_click")

    $SettingsMenu/SaveGameButton.connect("button_up", self, "_on_gui_event", [ "save_game_clicked" ])
    $SettingsMenu/ExitGameButton.connect("button_up", self, "_on_gui_event", [ "exit_game_clicked" ])
    $GameOverMenu/ExitGameButton.connect("button_up", self, "_on_gui_event", [ "exit_game_clicked" ])

func show_game_over_menu():
    $GameOverMenu.show()

func _on_gui_event(event_name: String):
    if event_name == "start_wave_clicked":
        self._update_start_pause_button()

    emit_signal("command_send", event_name)

func _on_building_menu_event(construction_type: int):
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
        $StartWaveButton.texture_normal = pause_texture
    else:
        $StartWaveButton.texture_normal = start_texture
    is_play_button_pressed = not is_play_button_pressed
