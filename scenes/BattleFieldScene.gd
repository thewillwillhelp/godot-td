extends Node2D

export (PackedScene) var mob_scene: PackedScene

var tower_scene: PackedScene = preload("res://scenes/towers/SimpleTower.tscn")
var utils: GDScript = preload("res://utils/Utils.gd")
var icon_destroy_construction = preload("res://assets/images/destroy-construction.png")
var icons_sprite_set = preload("res://assets/images/SpriteSet.png")

const PREVIEW_TOWER_RECT: Rect2 = Rect2(50, 0, 50, 100)
const PREVIEW_CANNON_TOWER_RECT: Rect2 = Rect2(100, 0, 50, 100)
const PREVIEW_WALL_RECT: Rect2 = Rect2(0, -50, 50, 100)
const PREVIEW_DESTROY_CONSTRUCTION_RECT: Rect2 = Rect2(0, -100, 100, 200)

const BUILDING_AREA_ALLOWED_TOP_LEFT = Vector2(1, 1)
const BUILDING_AREA_ALLOWED_BOTTOM_RIGHT = Vector2(6, 13)
const DEFAULT_BATTLEFIELD_ROWS_NUMBER = 15
const DEFAULT_BATTLEFIELD_COLUMNS_NUMBER = 8
const GRASS_TILE_INDEX = 1
const STONE_WALL_TILE_INDEX = 0

signal battlefield_data_updated

# mainTileMap should reflect this data:
var battlefield_data = []

var start_position = Vector2(3, 0)
var end_position = Vector2(4, 14)
var main_tile_map: TileMap
var background_tile_map: TileMap
var target_building: String = ""
var current_wave_counter: int = 0

var score: int = 0
var gold: int = 2225
var game_level: int = 1
# var wood: int = 0
# var steel: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    main_tile_map = $BattleField/MainTileMap
    background_tile_map = $BattleField/BackgroundTileMap
    start_new_game()

func start_new_game():
    battlefield_data = create_initial_battlefield(DEFAULT_BATTLEFIELD_COLUMNS_NUMBER, DEFAULT_BATTLEFIELD_ROWS_NUMBER)
    update_battle_field_view(battlefield_data)
    update_score_label()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func add_construction(position, construction_name):
    var cell_position = main_tile_map.world_to_map(position)

    if "construction" in battlefield_data[cell_position.y][cell_position.x]:
        return

    if battlefield_data[cell_position.y][cell_position.x].type == 0:
        return

    var tile_name: String

    var tower: Node2D
    if construction_name == "tower-basement":
        tile_name = "tower-basement"
        tower = tower_scene.instance()
        tower.entity_type = 1
    elif construction_name == "tower":
        tile_name = "ballista-tower"
        tower = tower_scene.instance()
        tower.entity_type = 2
    elif construction_name == "cannon_tower":
        tile_name = "cannon-tower"
        tower = tower_scene.instance()
        tower.entity_type = 3
    else:
        return

    tower.position = main_tile_map.map_to_world(cell_position) + Vector2(25, 25)
    tower.connect("tower_was_selected", self, "on_tower_selected")
    $BattleField.add_child(tower)
    tower.battle_field = $BattleField

    var construction_tile_index = main_tile_map.get_tileset().find_tile_by_name(tile_name)

    var unwalkable_grass_tile = background_tile_map.get_tileset().find_tile_by_name("grass_non_walkable")
    background_tile_map.set_cellv(cell_position, unwalkable_grass_tile)

    battlefield_data[cell_position.y][cell_position.x].type = construction_tile_index
    battlefield_data[cell_position.y][cell_position.x].construction = tower
    update_battle_field_view(battlefield_data)

func remove_construction(position):
    var construction_tile = main_tile_map.get_tileset().find_tile_by_name("grass")
    var cell_position = main_tile_map.world_to_map(position)
    main_tile_map.set_cellv(cell_position, construction_tile)

    battlefield_data[cell_position.y][cell_position.x].type = 1
    if "construction" in battlefield_data[cell_position.y][cell_position.x]:
        battlefield_data[cell_position.y][cell_position.x].construction.queue_free()
        battlefield_data[cell_position.y][cell_position.x].erase("construction")

    update_battle_field_view(battlefield_data)

func add_tower_basement(position):
    if gold < 5:
        return
    add_construction(position, "tower-basement")
    gold -= 5
    update_score_label()

func add_tower(position, construction_name):
    var tower_cost: int

    if construction_name == "tower":
        tower_cost = 10
    elif construction_name == "cannon_tower":
        tower_cost = 20

    if self.gold < tower_cost:
        return

    add_construction(position, construction_name)

    gold -= tower_cost
    update_score_label()

func _on_mob_create_timer_timeout():
    if current_wave_counter == 0:
        $mob_create_timer.stop()
    else:
        current_wave_counter -= 1
        create_entity()

func raise_game_level():
    set_game_level(game_level + 1)

func set_game_level(new_game_level: int):
    game_level = new_game_level
    update_score_label()

func check_and_update_game_level():
    if score / (5.0* (game_level*2)) > game_level:
        raise_game_level()
        pass

# remove mobs when they reach the exit
func _on_ExitArea_area_entered(area: Area2D) -> void:
    if not "entity_class" in area:
        return

    if area.entity_class == "Enemy":
        area.queue_free()
        score -= 10
        update_score_label()

func on_kill_mob():
    gold += rand_range(1, 2)
    score += 1 * game_level
    check_and_update_game_level()
    update_score_label()

func create_entity():
    var next_mob = mob_scene.instance()
    next_mob.entity_type = 1
    if game_level > 5:
        if randi() % 100 > (100 - game_level):
            next_mob.entity_type = 2

    next_mob.difficulty_modifier = game_level

    $BattleField.add_child(next_mob)
    next_mob.position = main_tile_map.map_to_world(start_position) + main_tile_map.cell_size / 2

    var target_position = main_tile_map.map_to_world(end_position) + main_tile_map.cell_size
    next_mob.world_tilemap = main_tile_map
    next_mob.target_position = end_position
    next_mob.connect("was_killed", self, "on_kill_mob")
    self.connect("battlefield_data_updated", next_mob, "on_battlefield_data_changed")
    next_mob.update_escaped_path(battlefield_data)

func update_score_label():
    # @TODO separte these labels
    $ScoreLabel.text = "Score: %d\nGold: %d\nLevel: %d" % [score, gold, game_level]



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

    var mobs_for_level = game_level
    if mobs_for_level > 20: mobs_for_level = 20
    var bonus_mobs = (randi() % (game_level + 2)) % 10

    current_wave_counter = mobs_for_level + bonus_mobs
    $mob_create_timer.start()


func _on_BattleField_gui_input(event):
    if event is InputEventMouseButton:
        var battleFieldRect = $BattleField.get_rect()
        if event.button_index == BUTTON_LEFT:
            if event.is_pressed():
                if (not is_cell_available_for_building(event.position - battleFieldRect.position) and
                    target_building != "DESTROY"):
                    return

                if target_building == "wall":
                    add_tower_basement(event.position - battleFieldRect.position)
                elif target_building == "tower" or target_building == "cannon_tower":
                    add_tower(event.position - battleFieldRect.position, target_building)
                elif target_building == "DESTROY":
                    remove_construction(event.position - battleFieldRect.position)

                # target_building = ""
                update_building_preview(target_building)

        if event.button_index == BUTTON_RIGHT:
            pass

    elif event is InputEventMouseMotion:
        pass

func update_building_preview(building_target: String = ""):
    var building_preview_sprite = $SelectionPreview/Button/Sprite
    building_preview_sprite.set_scale(Vector2(2, 2))
    building_preview_sprite.texture = icons_sprite_set
    if building_target == "tower":
        building_preview_sprite.set_region_rect(PREVIEW_TOWER_RECT)
        building_preview_sprite.visible = true
    elif building_target == "cannon_tower":
        building_preview_sprite.set_region_rect(PREVIEW_CANNON_TOWER_RECT)
        building_preview_sprite.visible = true
    elif building_target == "wall":
        building_preview_sprite.set_region_rect(PREVIEW_WALL_RECT)
        building_preview_sprite.visible = true
    elif building_target == "DESTROY":
        building_preview_sprite.set_scale(Vector2(1, 1))
        building_preview_sprite.texture = icon_destroy_construction
        building_preview_sprite.set_region_rect(PREVIEW_DESTROY_CONSTRUCTION_RECT)
        building_preview_sprite.visible = true
    else:
        building_preview_sprite.visible = false

func is_cell_available_for_building(position: Vector2) -> bool:
    var cell_position = main_tile_map.world_to_map(position)
    var current_cell_type: int = battlefield_data[cell_position.y][cell_position.x].type
    battlefield_data[cell_position.y][cell_position.x].type = 0
    var came_from_map = utils.get_came_from_map(battlefield_data, start_position, end_position)
    var path = utils.find_the_path(came_from_map, start_position, end_position)
    battlefield_data[cell_position.y][cell_position.x].type = current_cell_type
    return len(path) > 0

func create_initial_battlefield(width: int, height: int):
    var battlefield_data = []
    battlefield_data.resize(height)

    for row_index in range(0, height):
        battlefield_data[row_index] = []
        battlefield_data[row_index].resize(width)
        for cell_index in range(0, width):
            var cell = { "type": GRASS_TILE_INDEX }
            if ((cell_index == 0 or cell_index == width-1 or
                row_index == 0 or row_index == height-1) and
                start_position.distance_squared_to(Vector2(cell_index, row_index)) != 0 and
                end_position.distance_squared_to(Vector2(cell_index, row_index)) != 0):
                cell.type = 0

            battlefield_data[row_index][cell_index] = cell

    return battlefield_data

func update_battle_field_view(battlefield_data):
    for row_index in range(0, len(battlefield_data)):
        for cell_index in range(0, len(battlefield_data[row_index])):
            main_tile_map.set_cell(cell_index, row_index, battlefield_data[row_index][cell_index].type)

    emit_signal("battlefield_data_updated", battlefield_data)


func _on_SelectionPreview_pressed():
    target_building = ""
    update_building_preview(target_building)

func on_tower_selected(tower: Node2D):
    if target_building == "DESTROY":
        #tower.queue_free()
        self.remove_construction(tower.position)
    else:
        tower.toggle_radius_visibility()


func _on_BuildingMenu_building_target_was_selected(construction_type):
    if construction_type == 0:
        target_building = "DESTROY"
    elif construction_type == 1:
        target_building = "wall"
    elif construction_type == 2:
        target_building = "tower"
    elif construction_type == 3:
        target_building = "cannon_tower"
    update_building_preview(target_building)

