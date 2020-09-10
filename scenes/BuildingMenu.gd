extends Node2D

signal wall_selected
signal tower_selected
signal close_menu
signal destroy_construction_selected

# Called when the node enters the scene tree for the first time.
func _ready():
    $StoneWallButton.connect("pressed", self, "emit_wall_selected")
    $TowerButton.connect("pressed", self, "emit_tower_selected")
    $CloseButton.connect("pressed", self, "emit_close_menu")
    $DestroyButton.connect("pressed", self, "emit_destroy_construction_selected")
    pass # Replace with function body.

func emit_wall_selected():
    emit_signal("wall_selected")

func emit_tower_selected():
    emit_signal("tower_selected")

func emit_close_menu():
    emit_signal("close_menu")

func emit_destroy_construction_selected():
    emit_signal("destroy_construction_selected")

