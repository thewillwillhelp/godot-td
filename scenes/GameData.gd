extends Node

var data: Dictionary
var battle_field_scene: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)

func set_game_data(game_data: Dictionary) -> void:
    self.data = game_data

func set_battle_field_scene(battle_field_scene: Node2D) -> void:
    self.battle_field_scene = battle_field_scene

func reduce_boosters_number(type: String, amount: int = 1) -> void:
    self.data[type] -= amount
    self.battle_field_scene.update_score_label()

func increase_boosters_number(type: String, amount: int = 1) -> void:
    self.data[type] += amount
    self.battle_field_scene.update_score_label()
