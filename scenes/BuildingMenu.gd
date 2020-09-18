extends Node2D

signal building_target_was_selected
signal close_menu

# Called when the node enters the scene tree for the first time.
func _ready():
    $StoneWallButton.connect("pressed", self, "emit_building_menu_selection", [ 1 ])
    $TowerButton.connect("pressed", self, "emit_building_menu_selection", [ 2 ])
    $CloseButton.connect("pressed", self, "emit_close_menu")
    $DestroyButton.connect("pressed", self, "emit_building_menu_selection", [ 0 ])
    $CannonTowerButton.connect("pressed", self, "emit_building_menu_selection", [ 3 ])

func emit_building_menu_selection(construction_type):
    emit_signal("building_target_was_selected", construction_type)

func emit_close_menu():
    emit_signal("close_menu")

