extends Node2D

signal tower_was_selected

var bullet_scene: PackedScene = preload("res://scenes/bullets/Simple_Bullet.tscn")
var battle_field: Node
var entity_class = "Construction"
var entity_type = 1
var bullet_type = 0
var cooldown_time: int = 1
var radius = 150
var radius_is_visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)

    if self.entity_type == 1:
        $Sprite.region_rect = Rect2(0, -50, 50, 100)
        self.bullet_type = 0
    elif self.entity_type == 2:
        $Sprite.region_rect = Rect2(50, 0, 50, 100)
        self.radius = 175
        self.cooldown_time = 1
        self.bullet_type = 1
    elif self.entity_type == 3:
        $Sprite.region_rect = Rect2(100, 0, 50, 100)
        self.radius = 100
        self.cooldown_time = 1.5
        self.bullet_type = 2

    if self.bullet_type > 0:
        $shot_timer.wait_time = self.cooldown_time
        $shot_timer.start()

func _draw():
    if radius_is_visible:
        self.draw_arc(Vector2() , self.radius, 0, 100, 20, Color.red, 2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func shoot_enemy() -> void:
    if not bullet_scene:
        return

    var target_mob: Node2D = get_target_mob()
    if not target_mob:
        return

    var bullet = bullet_scene.instance()
    bullet.entity_type = self.bullet_type
    bullet.position = position
    battle_field.add_child(bullet)
    bullet.target = target_mob.position
    pass

func get_target_mob():
    if not battle_field:
        print_debug("no battle_field")
        return

    for child in battle_field.get_children():
        if (("entity_class" in child) and
            child.entity_class == "Enemy" and
            child.position.distance_to(self.position) < radius):
                return child

func _on_shot_timer_timeout():
    shoot_enemy()

func _on_Control_gui_input(event: InputEvent):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            if event.is_pressed():
                # toggle_radius_visibility()
                self.emit_signal("tower_was_selected", self)


func toggle_radius_visibility():
    if self.entity_type == 1:
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
