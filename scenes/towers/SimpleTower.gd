extends Node2D

var bullet_scene: PackedScene = preload("res://scenes/bullets/Simple_Bullet.tscn")
var battle_field: Node
var cooldown_time: int = 1
# var bull = 

# Called when the node enters the scene tree for the first time.
func _ready():
    set_process(false)
    # battle_field = get_parent()
    $shot_timer.wait_time = cooldown_time
    $shot_timer.start()
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func shoot_enemy() -> void:
    # print_debug("shot")
    if not bullet_scene:
        return
        
    var target_mob: Node2D = get_target_mob()
    if not target_mob:
        # print_debug("no mob")
        return
        
    var bullet = bullet_scene.instance()
    bullet.position = position
    battle_field.add_child(bullet)
    bullet.target = target_mob.position
    pass
    
func get_target_mob():
    if not battle_field:
        print_debug("no battle_field")
        return
    
    for child in battle_field.get_children():
        if "enemy_type" in child:
            return child

func _on_shot_timer_timeout():
    shoot_enemy()
    pass # Replace with function body.

    
