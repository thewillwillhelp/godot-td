extends Control

func _ready():
    var load_game_button = $TextureRect/VBoxContainer/CenterContainer/MenuButtons/LoadFreeGameButton
    var file_to_load = File.new()
    if file_to_load.file_exists("user://savegame.save"):
        load_game_button.disabled = false
    else:
        load_game_button.disabled = true

func _on_NewFreeGameButton_pressed():
    get_tree().change_scene("res://scenes/MainScene.tscn")


func _on_ExitButton_pressed():
    get_tree().quit()


func _on_LoadFreeGameButton_pressed():
    globals.game_should_be_loaded = true
    get_tree().change_scene("res://scenes/MainScene.tscn")
