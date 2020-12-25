extends Node2D

signal tower_was_selected
signal construction_request_destroying

const PREVIEW_TOWER_RECT: Rect2 = Rect2(50, 0, 50, 100)
const PREVIEW_CANNON_TOWER_RECT: Rect2 = Rect2(100, 0, 50, 100)
const PREVIEW_WALL_RECT: Rect2 = Rect2(0, -50, 50, 100)
const PREVIEW_BARRICADE_RECT := Rect2(0, 0, 100, 100)
const TEXTURE_BARRICADE = preload("res://assets/images/barricade.png")
const TEXTURE_SPRITESET = preload("res://assets/images/SpriteSet.png")

const CONSTRUCTION_TYPE__WALL = "WALL"
const CONSTRUCTION_TYPE__TOWER_BALLISTA = "TOWER_BALLISTA"
const CONSTRUCTION_TYPE__TOWER_CANNON = "TOWER_CANNON"
const CONSTRUCTION_TYPE__BARRICADE = "BARRICADE"

var bullet_scene: PackedScene = preload("res://scenes/bullets/Simple_Bullet.tscn")
var battle_field: Node
var entity_class = "Construction"
var max_durablity = 20
var durability = 20
var entity_type = 1
var bullet_type = 0
var cooldown_time: float = 1
var radius = 150
var radius_is_visible = false
var is_ready_to_shot = false
var reloading_timer_counter = 0
var movement_factor = 1
var attack_speed_booster = 0
var range_booster = 0
var damage_booster = 0
var can_be_improved = false

var DEFAULT_DATA = {
    CONSTRUCTION_TYPE__WALL: {
        "is_sprite_visible": false,
        "texture": TEXTURE_SPRITESET,
        "region_rect": PREVIEW_WALL_RECT,
        "bullet_type": 0,
        "sprite_offset": Vector2(0, -25)
    },
    CONSTRUCTION_TYPE__TOWER_BALLISTA: {
        "is_sprite_visible": false,
        "texture": TEXTURE_SPRITESET,
        "region_rect": PREVIEW_TOWER_RECT,
        "bullet_type": 1,
        "sprite_offset": Vector2(0, -25),
        "cooldown_time": 1,
        "radius": 175,
        "can_be_improved": true
    },
    CONSTRUCTION_TYPE__TOWER_CANNON: {
        "is_sprite_visible": false,
        "texture": TEXTURE_SPRITESET,
        "region_rect": PREVIEW_CANNON_TOWER_RECT,
        "bullet_type": 2,
        "sprite_offset": Vector2(0, -25),
        "cooldown_time": 1.5,
        "radius": 100,
        "can_be_improved": true
    },
    CONSTRUCTION_TYPE__BARRICADE: {
        "is_sprite_visible": true,
        "texture": TEXTURE_BARRICADE,
        "region_rect": PREVIEW_BARRICADE_RECT,
        "bullet_type": 0,
        "sprite_offset": Vector2(0, 0),
        "sprite_scale": Vector2(0.5, 0.5),
        "movement_factor": 0.5
    }
}

func get_type_of_construction_by_id(type_id: int) -> String:
    if type_id == 1:
        return CONSTRUCTION_TYPE__WALL
    if type_id == 2:
        return CONSTRUCTION_TYPE__TOWER_BALLISTA
    if type_id == 3:
        return CONSTRUCTION_TYPE__TOWER_CANNON
    if type_id == 4:
        return CONSTRUCTION_TYPE__BARRICADE

    return ""


# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)

    var construction_type = self.get_type_of_construction_by_id(self.entity_type)
    var default_construction_data = DEFAULT_DATA[construction_type]

    $Sprite.texture = default_construction_data["texture"]
    $Sprite.region_rect = default_construction_data["region_rect"]
    $Sprite.set_offset(default_construction_data["sprite_offset"])
    $Sprite.visible = default_construction_data["is_sprite_visible"]
    if "sprite_scale" in default_construction_data:
        $Sprite.set_scale(default_construction_data["sprite_scale"])

    self.bullet_type = default_construction_data["bullet_type"]
    if "movement_factor" in default_construction_data:
        self.movement_factor = default_construction_data["movement_factor"]
    if "can_be_improved" in default_construction_data:
        self.can_be_improved = default_construction_data["can_be_improved"]

    self.recalculate_parameters()

    if self.bullet_type > 0:
        self.set_process(true)
    else:
        $TextureProgress.visible = false

func _draw():
    if self.radius_is_visible:
        self.draw_arc(Vector2() , self.radius, 0, 2*PI, 31, Color.red, 2)

func _process(delta):
    if not self.is_ready_to_shot:
        self.reloading_timer_counter += delta
        self.update_loading_progress_indicator()
    else:
        self.shoot_enemy()

    if self.reloading_timer_counter >= self.cooldown_time:
        self.is_ready_to_shot = true


func shoot_enemy() -> void:
    if not self.bullet_scene:
        return

    var target_mob: Node2D = self.get_target_mob()
    if not target_mob:
        return

    var bullet = bullet_scene.instance()
    bullet.entity_type = self.bullet_type
    bullet.position = self.position
    battle_field.add_child(bullet)
    bullet.target = target_mob.position
    bullet.damage_multiplier = self.damage_booster * 2

    self.is_ready_to_shot = false
    self.reloading_timer_counter = 0


func get_target_mob():
    if not battle_field:
        print_debug("no battle_field")
        return

    for child in battle_field.get_children():
        if (("entity_class" in child) and
            child.entity_class == "Enemy" and
            child.position.distance_to(self.position) < radius):
                return child

func _on_Control_gui_input(event: InputEvent):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            if not event.is_pressed():
                self.emit_signal("tower_was_selected", self)


func toggle_radius_visibility():
    if self.entity_type == 1:
        return

    if self.entity_type == 4:
        return

    if self.radius_is_visible:
        self.hide_radius()
    else:
        self.show_radius()

func show_radius():
    self.radius_is_visible = true
    self.update()

func hide_radius():
    self.radius_is_visible = false
    self.update()

func update_loading_progress_indicator():
    if self.entity_type > 0:
        $TextureProgress.value = self.reloading_timer_counter / self.cooldown_time * 100

func reduce_durability():
    if self.entity_type != 4:
        return

    self.durability -= 1
    if self.durability <= 0:
        self.emit_signal("construction_request_destroying")

func upgrade(type: String, game_data: Node) -> bool:
    var current_game_data = game_data.data

    if (self.attack_speed_booster > 0 or
        self.range_booster > 0 or
        self.damage_booster > 0):
        return false

    if type == "range":
        if current_game_data.topaz < 1:
            return false

        game_data.reduce_boosters_number("topaz")
        self.range_booster = 1

    if type == "damage":
        if current_game_data.ruby < 1:
            return false

        game_data.reduce_boosters_number("ruby")
        self.damage_booster = 1

    if type == "attack_speed":
        if current_game_data.sapphire < 1:
            return false

        game_data.reduce_boosters_number("sapphire")
        self.attack_speed_booster = 1

    self.recalculate_parameters()
    self.update()
    return true


func recalculate_parameters():
    var construction_type = self.get_type_of_construction_by_id(self.entity_type)
    var default_construction_data = DEFAULT_DATA[construction_type]

    if "radius" in default_construction_data:
        self.radius = default_construction_data["radius"] * (1 + self.range_booster * 0.2)
    if "cooldown_time" in default_construction_data:
        self.cooldown_time = default_construction_data["cooldown_time"] * (1 - self.attack_speed_booster * 0.2)

