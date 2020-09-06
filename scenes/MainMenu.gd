extends Control


func _on_NewFreeGameButton_pressed():
	get_tree().change_scene("res://scenes/MainScene.tscn")


func _on_ExitButton_pressed():
	get_tree().quit()
