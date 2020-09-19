extends Node2D

var entity_class: String = "Bullet"
var entity_type: int = 1
var target: Vector2 setget set_target
var speed: int = 200
var min_damage: int = 1
var max_damage: int = 5

# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)

    if entity_type == 1:
        self.min_damage = 1
        self.max_damage = 5
        self.speed = 250
    elif entity_type == 2:
        self.min_damage = 5
        self.max_damage = 15
        self.speed = 175

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    move_to_target(delta * speed)

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
