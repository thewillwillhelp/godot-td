extends Node2D

signal was_killed

var escape_path = [] setget set_path
var speed = 100
var world_tilemap: TileMap
var processed_steps = 0
var enemy_type = 1

# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    var distance = delta * speed
    move_along_path(distance)

func move_along_path(distance):
    var start_position = position
    for i in range(escape_path.size()):
        var distance_to_next = start_position.distance_to(escape_path[0])
        if distance <= distance_to_next and distance >= 0:
            position = start_position.linear_interpolate(escape_path[0], distance / distance_to_next)
            break
        elif distance < 0:
            position = escape_path[0]
            set_process(false)
        start_position = escape_path[0]
        escape_path.remove(0)

func set_path(value):
    escape_path = value
    if value.size() == 0:
        return
    set_process(true)


func _on_Area2D_area_shape_entered(area_id, area, area_shape, self_shape):
    # print_debug("Collision, area_shape_entered")
    pass # Replace with function body.


func _on_Area2D_area_entered(area: Area2D) -> void:
    if "bullet_type" in area:
        # print_debug("Collision, area_entered, BULLET")
        emit_signal("was_killed")
        queue_free()
        area.queue_free()
    else:
        pass
        #print_debug("Not a bullet")

