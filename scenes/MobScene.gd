extends Node2D

signal was_killed

const HP_INDICATOR_MAX_WIDTH = 38

var escape_path = [] setget set_path
var difficulty_modifier = 1
var hit_points = 4
var max_hp = 4
var speed = 100
var world_tilemap: TileMap
var enemy_type = 1

# Called when the node enters the scene tree for the first time.
func _ready():
    max_hp = difficulty_modifier * max_hp
    hit_points = max_hp
    update_hp_label()
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

func update_hp_label():
    var life_indicator = $HpIndicator/LifeIndicator
    var hp_indicator_width = float(hit_points)/float(max_hp)*HP_INDICATOR_MAX_WIDTH
    life_indicator.rect_size.x = hp_indicator_width

func receive_damage(bullet: Area2D):
    var damage_range = bullet.max_damage - bullet.min_damage
    var damage = bullet.min_damage + randi() % damage_range
    hit_points = hit_points - damage

    update_hp_label()
    # @TODO add some animation

    if hit_points <= 0:
        emit_signal("was_killed")
        queue_free()

func _on_Area2D_area_shape_entered(area_id, area, area_shape, self_shape):
    # print_debug("Collision, area_shape_entered")
    pass # Replace with function body.


func _on_Area2D_area_entered(area: Area2D) -> void:
    if "bullet_type" in area:
        # @TODO damage depends on bullet_type
        receive_damage(area)
        area.queue_free()

