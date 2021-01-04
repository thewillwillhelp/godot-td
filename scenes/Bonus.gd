extends Node2D

signal clicked

func _ready():
    set_process(false)

func _on_Coin_pressed() -> void:
    self.emit_signal("clicked")
    self.queue_free()
