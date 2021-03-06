extends Node2D

var ballista_bullet_texture = preload("res://assets/images/bullets/simple_bullet.png")
var cannon_bullet_texture = preload("res://assets/images/bullets/simple_bullet_dark_blue_with_blink.png")

var entity_class: String = "Bullet"
var entity_type: int = 1
var target: Vector2 setget set_target
var speed: int = 200
var min_damage: int = 1
var max_damage: int = 5
var max_affected_targets: int = 1
var affected_targets: int = 0
var damage_multiplier: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)

    if entity_type == 1:
        self.min_damage = 1 * damage_multiplier
        self.max_damage = 5 * damage_multiplier
        self.speed = 250
        $Sprite.texture = ballista_bullet_texture
    elif entity_type == 2:
        self.min_damage = 5 * damage_multiplier
        self.max_damage = 15 * damage_multiplier
        self.speed = 175
        self.max_affected_targets = 5
        $Sprite.texture = cannon_bullet_texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    move_to_target(delta * speed)

func move_to_target(step_size):
    var distance_to_next = self.position.distance_to(self.target)
    if step_size <= distance_to_next and step_size >= 0:
        self.position = self.position.linear_interpolate(self.target, step_size / distance_to_next)
    else:
        self.set_process(false)
        self.queue_free()

func set_target(value: Vector2):
    target = value
    set_process(true)

func is_active():
    return self.max_affected_targets > self.affected_targets
