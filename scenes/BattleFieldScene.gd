extends Node2D

export (PackedScene) var mob_scene: PackedScene

var tower_scene: PackedScene = preload("res://scenes/towers/SimpleTower.tscn")

const PREVIEW_TOWER_RECT: Rect2 = Rect2(50, 0, 50, 100)
const PREVIEW_WALL_RECT: Rect2 = Rect2(0, -50, 50, 100)

var field_structures = []
var start_position = Vector2(3, 0)
var end_position = Vector2(4, 14)
var main_tile_map: TileMap
var background_tile_map: TileMap
var target_building: String = ""
var current_wave_counter: int = 0

var score: int = 0
var gold: int = 10
# var wood: int = 0
# var steel: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    main_tile_map = $BattleField/Navigation2D/MainTileMap
    background_tile_map = $BattleField/Navigation2D/BackgroundTileMap
    update_score_label()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func is_point_in_area(point, area_start, area_end):
    if point.x < area_start.x || point.x > area_end.x:
        return false
    if point.y < area_start.y || point.y > area_end.y:
        return false
    return true

func add_construction(position, construction_name):
    var construction_tile = main_tile_map.get_tileset().find_tile_by_name(construction_name)
    var cell_position = main_tile_map.world_to_map(position)
    main_tile_map.set_cellv(cell_position, construction_tile)

    var unwalkable_grass_tile = background_tile_map.get_tileset().find_tile_by_name("grass_non_walkable")
    background_tile_map.set_cellv(cell_position, unwalkable_grass_tile)

    remove_hidden_structures(cell_position)

func add_stone_wall(position):
    if gold < 5:
        return
    add_construction(position, "tower-basement")
    gold -= 5
    update_score_label()

func add_tower(position):
    if gold < 10:
        return

    add_construction(position, "ballista-tower")

    var tower = tower_scene.instance()
    tower.position = position
    $BattleField.add_child(tower)
    tower.battle_field = $BattleField
    var position_in_tilemap = main_tile_map.world_to_map(position)
    field_structures.push_back({ 'tower': tower, 'position': position_in_tilemap })

    gold -= 10
    update_score_label()

func remove_hidden_structures(position: Vector2):
    var index_of_hidden_structer_by_position: int
    var should_remove_hidden_structure: bool = false

    for index in field_structures.size():
        if position.distance_squared_to(field_structures[index].position) == 0:
            index_of_hidden_structer_by_position = index
            should_remove_hidden_structure = true
            break

    if should_remove_hidden_structure:
        $BattleField.remove_child(field_structures[index_of_hidden_structer_by_position].tower)
        field_structures.remove(index_of_hidden_structer_by_position)


func find_path(target_position, entity):
    var mob = entity
    var path = $BattleField/Navigation2D.get_simple_path(mob.position, target_position, true)
    $BattleField/Line2D.points = path
    mob.escape_path = path

func _on_mob_create_timer_timeout():
    if current_wave_counter == 0:
        $mob_create_timer.stop()
    else:
        current_wave_counter -= 1
        create_entity()


# remove mobs when they reach the exit
func _on_ExitArea_area_entered(area: Area2D):
    area.get_parent().queue_free()
    score -= 10
    update_score_label()

func on_kill_mob():
    gold += rand_range(1, 10)
    score += 1
    update_score_label()

func create_entity():
    var next_mob = mob_scene.instance()
    $BattleField.add_child(next_mob)
    next_mob.position = main_tile_map.map_to_world(start_position) + main_tile_map.cell_size / 2

    var target_position = main_tile_map.map_to_world(end_position) + main_tile_map.cell_size
    next_mob.connect("was_killed", self, "on_kill_mob")
    find_path(target_position, next_mob)

func update_score_label():
    $ScoreLabel.text = "Score: %d\nGold: %d" % [score, gold]


func _on_BuildingMenu_tower_selected():
    target_building = "tower"
    update_building_preview(target_building)


func _on_BuildingMenu_wall_selected():
    target_building = "wall"
    update_building_preview(target_building)


func _on_BuildingMenu_close_menu():
    $BuildingMenu.hide()

func _on_BuildingMenuButton_pressed():
    if not $BuildingMenu.visible:
        $BuildingMenu.show()
    else:
        $BuildingMenu.hide()
    pass # Replace with function body.


func _on_StartWaveButton_pressed():
    if current_wave_counter > 0:
        return

    current_wave_counter = randi() % 20
    $mob_create_timer.start()


func _on_BattleField_gui_input(event):
    if event is InputEventMouseButton:
        var battleFieldRect = $BattleField.get_rect()
        if event.button_index == BUTTON_LEFT:
            if event.is_pressed():
                # print("Mouse Click/Unclick at: ", event.position)
                # if is_point_in_area(event.position, battleFieldRect.position, battleFieldRect.end):
                if target_building == "wall":
                    add_stone_wall(event.position - battleFieldRect.position)
                elif target_building == "tower":
                    add_tower(event.position - battleFieldRect.position)

                target_building = ""
                update_building_preview()

        if event.button_index == BUTTON_RIGHT:
            pass

    elif event is InputEventMouseMotion:
        pass

func update_building_preview(building_target: String = ""):
    var building_preview_sprite = $SelectionPreview/Button/Sprite
    if building_target == "tower":
        building_preview_sprite.set_region_rect(PREVIEW_TOWER_RECT)
        building_preview_sprite.visible = true
    elif building_target == "wall":
        building_preview_sprite.set_region_rect(PREVIEW_WALL_RECT)
        building_preview_sprite.visible = true
    else:
        building_preview_sprite.visible = false

