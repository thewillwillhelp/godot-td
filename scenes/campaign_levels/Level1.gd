extends Node

var battlefield_raw_data = [
    [0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 2, 4, 1, 1, 1, 1, 1, 1, 0],
    [0, 2, 2, 1, 2, 2, 2, 1, 1, 0],
    [0, 4, 2, 1, 2, 4, 2, 1, 1, 0],
    [0, 2, 2, 4, 2, 1, 2, 1, 1, 0],
    [0, 1, 2, 1, 2, 1, 2, 1, 1, 0],
    [0, 1, 2, 2, 2, 1, 2, 2, 1, 0],
    [0, 1, 1, 1, 1, 1, 4, 2, 5, 0],
    [0, 1, 1, 1, 1, 1, 1, 2, 2, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
]

var default_data: Dictionary = {
    "start_position": Vector2(1, 0), # Vector2(0, 1),
    "end_position": Vector2(8, 9), # Vector2(4, 14),
    "score": 0,
    "field_width": 10,
    "field_height": 10,
    "gold": 10,
    "game_level": 1,
    "lives": 25,
    "battlefield_raw_data": battlefield_raw_data,
    "max_waves": 3
}

# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)
