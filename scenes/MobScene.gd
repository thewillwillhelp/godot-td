extends Node2D

var utils: GDScript = preload("res://utils/Utils.gd")

"""
lvl  entity_type  max_hp   speed
 1       1          8        50
 2       1          16       50

 1       2          3        90
 2       2          6        90
"""

signal was_killed

# UI constants
const HP_INDICATOR_MAX_WIDTH = 38

# data object constants
var entity_class = "Enemy"
var entity_type = 1
var escape_path = [] setget set_path
var difficulty_modifier = 1
var hit_points = 4
var max_hp = 4
var speed = 50
var world_tilemap: TileMap
var came_from_map: Dictionary
# target position in tilemap cells
var target_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
    update_params_according_type()
    update_hp_label()
    set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    var distance = delta * speed
    move_along_path(distance)

func move_along_path(distance):
    var start_position = position
    update_path_line()
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
    if not bullet.is_active():
        return

    var damage_range = bullet.max_damage - bullet.min_damage
    var damage = bullet.min_damage + randi() % damage_range
    hit_points = hit_points - damage

    bullet.affected_targets += 1

    self.update_hp_label()
    # @TODO add some animation

    if hit_points <= 0:
        self.emit_signal("was_killed")
        self.queue_free()

func _on_Area2D_area_entered(area: Area2D) -> void:
    if not "entity_class" in area:
        return

    if area.entity_class == "Bullet":
        self.receive_damage(area)
        area.queue_free()

func on_battlefield_data_changed(updated_battlefield_data) -> void:
    update_escaped_path(updated_battlefield_data)

func update_escaped_path(battlefield_data) -> void:
    var current_cell_position = world_tilemap.world_to_map(position)
    var came_from_map = utils.get_came_from_map(battlefield_data, current_cell_position, target_position)
    var path = utils.find_the_path(came_from_map, current_cell_position, target_position)
    var escape_path = utils.convert_tilemap_positions_to_real(world_tilemap, path)
    update_path_line()
    set_path(escape_path)

func update_path_line():
    var path_line = []
    for step in escape_path:
        path_line.push_back(step - position)

    $Line2D.points = path_line

func update_params_according_type():
    if entity_type == 1:
        max_hp = 8
        speed = 50
    if entity_type == 2:
        max_hp = 3
        speed = 90

    max_hp = difficulty_modifier * max_hp
    hit_points = max_hp
