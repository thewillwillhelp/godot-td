extends Node2D

var bullet_type: String = "simple_bullet"
var target: Vector2 setget set_target
var speed: int = 200
var minimal_damage: int = 1
# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    move_to_target(delta * speed)
    pass

func move_to_target(step_size):
    var distance_to_next = position.distance_to(target)
    if step_size <= distance_to_next and step_size >= 0:
        position = position.linear_interpolate(target, step_size / distance_to_next)
    else:
        set_process(false)
        queue_free()

func set_target(value: Vector2):
    target = value
    set_process(true)
