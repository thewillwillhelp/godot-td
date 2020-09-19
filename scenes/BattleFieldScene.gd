extends Node2D

export (PackedScene) var mob_scene: PackedScene

var tower_scene: PackedScene = preload("res://scenes/towers/SimpleTower.tscn")
var utils: GDScript = preload("res://utils/Utils.gd")
var icon_destroy_construction = preload("res://assets/images/destroy-construction-v2.png")
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

var main_tile_map: TileMap
var background_tile_map: TileMap
var target_building: String = ""
var current_wave_counter: int = 0

"""
    Construction Types:
    type  |     value               |   tile index
    0       DESTROY - not a tile         -
    1       STONE WALL                   0
    2       GRASS (no construction)      1
    3       TOWER BASEMENT               4
    4       BALLISTA TOWER               5
    5       CANNON TOWER                 6
"""

const CONSTRUCTION_TYPE_DESTROY = "DESTROY"
const CONSTRUCTION_TYPE_STONE_WALL = "STONE WALL"
const CONSTRUCTION_TYPE_GRASS = "GRASS"
const CONSTRUCTION_TYPE_TOWER_BASEMENT = "TOWER BASEMENT"
const CONSTRUCTION_TYPE_BALLISTA_TOWER = "BALLISTA TOWER"
const CONSTRUCTION_TYPE_CANNON_TOWER = "CANNON TOWER"

const CONSTRUCTION_TYPES_COSTS: Dictionary = {
    "TOWER BASEMENT": 5,
    "BALLISTA TOWER": 10,
    "CANNON TOWER": 30
}

const CONSTRUCTION_TYPES_TILES: Dictionary = {
    "DESTROY": -1,
    "STONE WALL": 8,
    "GRASS": 1,
    "TOWER BASEMENT": 4,
    "BALLISTA TOWER":  5,
    "CANNON TOWER": 6
}

var default_game_data: Dictionary = {
    "battlefield_data": [],
    "start_position": self.get_random_border_position(), # Vector2(0, 1),
    "end_position": self.get_random_border_position(), # Vector2(4, 14),
    "score": 0,
    "gold": 25,
    "game_level": 1
}

var game_data: Dictionary = default_game_data.duplicate()

# Called when the node enters the scene tree for the first time.
func _ready():
    randomize()
    main_tile_map = $BattleField/MainTileMap
    background_tile_map = $BattleField/BackgroundTileMap
    if globals.game_should_be_loaded:
        self.load_game()
    else:
        self.start_game()

func start_game(is_game_new: bool = true):
    if is_game_new:
        self.game_data = default_game_data.duplicate()
        self.game_data.start_position = self.get_random_border_position()
        self.game_data.end_position = self.get_random_border_position(self.game_data.start_position)
        self.game_data.battlefield_data = create_initial_battlefield(DEFAULT_BATTLEFIELD_COLUMNS_NUMBER, DEFAULT_BATTLEFIELD_ROWS_NUMBER)

    $ExitArea.position = main_tile_map.map_to_world(self.game_data.end_position) + Vector2(25, 25)

    update_battle_field_view(self.game_data.battlefield_data)
    update_score_label()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func remove_construction(position):
    var battlefield_data = self.game_data.battlefield_data
    var cell_position = main_tile_map.world_to_map(position)

    main_tile_map.set_cellv(cell_position, CONSTRUCTION_TYPES_TILES[CONSTRUCTION_TYPE_GRASS])

    battlefield_data[cell_position.y][cell_position.x].type = CONSTRUCTION_TYPE_GRASS
    if "construction" in battlefield_data[cell_position.y][cell_position.x]:
        battlefield_data[cell_position.y][cell_position.x].construction.queue_free()
        battlefield_data[cell_position.y][cell_position.x].erase("construction")

    update_battle_field_view(battlefield_data)

func raise_game_level():
    set_game_level(self.game_data.game_level + 1)

func set_game_level(new_game_level: int):
    self.game_data.game_level = new_game_level
    update_score_label()

func check_and_update_game_level():
    if self.game_data.score / (5.0* (self.game_data.game_level*2)) > self.game_data.game_level:
        raise_game_level()
        pass

func create_entity():
    var next_mob = mob_scene.instance()
    next_mob.entity_type = 1
    if self.game_data.game_level > 5:
        if randi() % 100 > (100 - self.game_data.game_level):
            next_mob.entity_type = 2

    next_mob.difficulty_modifier = self.game_data.game_level

    $BattleField.add_child(next_mob)
    next_mob.position = main_tile_map.map_to_world(self.game_data.start_position) + main_tile_map.cell_size / 2

    var target_position = main_tile_map.map_to_world(self.game_data.end_position) + main_tile_map.cell_size
    next_mob.world_tilemap = main_tile_map
    next_mob.target_position = self.game_data.end_position
    next_mob.connect("was_killed", self, "on_kill_mob")
    self.connect("battlefield_data_updated", next_mob, "on_battlefield_data_changed")
    next_mob.update_escaped_path(self.game_data.battlefield_data)

func update_score_label():
    var score = self.game_data.score
    var gold = self.game_data.gold
    var game_level = self.game_data.game_level
    # @TODO separte these labels
    $ScoreLabel.text = "Score: %d\nGold: %d\nLevel: %d" % [score, gold, game_level]

func update_building_preview(building_target: String = ""):
    var building_preview_sprite = $SelectionPreview/Button/Sprite
    building_preview_sprite.set_scale(Vector2(2, 2))
    building_preview_sprite.texture = icons_sprite_set
    if building_target == CONSTRUCTION_TYPE_BALLISTA_TOWER:
        building_preview_sprite.set_region_rect(PREVIEW_TOWER_RECT)
        building_preview_sprite.visible = true
    elif building_target == CONSTRUCTION_TYPE_CANNON_TOWER:
        building_preview_sprite.set_region_rect(PREVIEW_CANNON_TOWER_RECT)
        building_preview_sprite.visible = true
    elif building_target == CONSTRUCTION_TYPE_TOWER_BASEMENT:
        building_preview_sprite.set_region_rect(PREVIEW_WALL_RECT)
        building_preview_sprite.visible = true
    elif building_target == CONSTRUCTION_TYPE_DESTROY:
        building_preview_sprite.set_scale(Vector2(1, 1))
        building_preview_sprite.texture = icon_destroy_construction
        building_preview_sprite.set_region_rect(PREVIEW_DESTROY_CONSTRUCTION_RECT)
        building_preview_sprite.visible = true
    else:
        building_preview_sprite.visible = false

func is_cell_available_for_building(position: Vector2) -> bool:
    var battlefield_data = self.game_data.battlefield_data

    var cell_position = main_tile_map.world_to_map(position)
    var current_cell_type: String = battlefield_data[cell_position.y][cell_position.x].type
    battlefield_data[cell_position.y][cell_position.x].type = CONSTRUCTION_TYPE_STONE_WALL
    var came_from_map = utils.get_came_from_map(battlefield_data, self.game_data.start_position, self.game_data.end_position)
    var path = utils.find_the_path(came_from_map, self.game_data.start_position, self.game_data.end_position)
    battlefield_data[cell_position.y][cell_position.x].type = current_cell_type
    return len(path) > 0

func create_initial_battlefield(width: int, height: int):
    var battlefield_data = []
    battlefield_data.resize(height)

    for row_index in range(0, height):
        battlefield_data[row_index] = []
        battlefield_data[row_index].resize(width)
        for cell_index in range(0, width):
            var cell = { "type": CONSTRUCTION_TYPE_GRASS }
            if ((cell_index == 0 or cell_index == width-1 or
                row_index == 0 or row_index == height-1) and
                self.game_data.start_position.distance_squared_to(Vector2(cell_index, row_index)) != 0 and
                self.game_data.end_position.distance_squared_to(Vector2(cell_index, row_index)) != 0):
                cell.type = CONSTRUCTION_TYPE_STONE_WALL

            battlefield_data[row_index][cell_index] = cell

    return battlefield_data

func update_battle_field_view(battlefield_data):
    for row_index in range(0, len(battlefield_data)):
        for cell_index in range(0, len(battlefield_data[row_index])):
            self.add_construction_to_battlefield(Vector2(cell_index, row_index), battlefield_data[row_index][cell_index].type)
            var tile_index = CONSTRUCTION_TYPES_TILES[battlefield_data[row_index][cell_index].type]
            self.main_tile_map.set_cell(cell_index, row_index, tile_index)

            self.background_tile_map.set_cell(cell_index, row_index, CONSTRUCTION_TYPES_TILES[CONSTRUCTION_TYPE_GRASS])

    emit_signal("battlefield_data_updated", battlefield_data)


func add_construction_to_battlefield(cell_position: Vector2, construction_type: String):
    if "construction" in self.game_data.battlefield_data[cell_position.y][cell_position.x]:
        return

    # stone tile
    if self.game_data.battlefield_data[cell_position.y][cell_position.x].type == CONSTRUCTION_TYPE_STONE_WALL:
        return

    var tile_name: String

    var tower: Node2D = tower_scene.instance()
    if construction_type == CONSTRUCTION_TYPE_TOWER_BASEMENT:
        tile_name = "tower-basement"
        tower.entity_type = 1
    elif construction_type == CONSTRUCTION_TYPE_BALLISTA_TOWER:
        tile_name = "ballista-tower"
        tower.entity_type = 2
    elif construction_type == CONSTRUCTION_TYPE_CANNON_TOWER:
        tile_name = "cannon-tower"
        tower.entity_type = 3
    else:
        tower.queue_free()
        return

    tower.position = main_tile_map.map_to_world(cell_position) + Vector2(25, 25)
    tower.connect("tower_was_selected", self, "on_tower_selected")
    $BattleField.add_child(tower)
    tower.battle_field = $BattleField

    self.game_data.battlefield_data[cell_position.y][cell_position.x].type = construction_type
    self.game_data.battlefield_data[cell_position.y][cell_position.x].construction = tower

func reset_game():
    for battlefield_row in game_data.battlefield_data:
        for battlefield_cell in battlefield_row:
            if "construction" in battlefield_cell:
                battlefield_cell.type = CONSTRUCTION_TYPE_GRASS
                battlefield_cell.construction.queue_free()
                battlefield_cell.erase("construction")

    $mob_create_timer.stop()
    self.current_wave_counter = 0
    self.remove_all_enemies()
    self.start_game()

func remove_all_enemies():
    for child in $BattleField.get_children():
        if ("entity_class" in child and
            child.entity_class == "Enemy"):
            child.queue_free()

func save_game():
    var file_to_save = File.new()
    file_to_save.open("user://savegame.save", File.WRITE)

    # prepare data to save:
    var data_to_save = self.game_data.duplicate()

    file_to_save.store_var(data_to_save)
    file_to_save.close()

func load_game():
    var file_to_load = File.new()
    if not file_to_load.file_exists("user://savegame.save"):
        return # Error! We don't have a save to load.

    file_to_load.open("user://savegame.save", File.READ)

    var loaded_game_data = file_to_load.get_var()
    file_to_load.close()

    # prepare loaded data
    for row in loaded_game_data.battlefield_data:
        for cell in row:
            if "construction" in cell:
                cell.erase("construction")

    self.reset_game()
    self.game_data = loaded_game_data
    self.start_game(false)

func get_random_border_position(to_keep_distance: Vector2 = Vector2()) -> Vector2:
    randomize()
    var side: int = randi() % 4
    var x: int = 0
    var y: int = 0
    if side == 0: # left
        y = (randi() % (DEFAULT_BATTLEFIELD_ROWS_NUMBER - 2)) + 1
    elif side == 1: # top
        x = (randi() % (DEFAULT_BATTLEFIELD_COLUMNS_NUMBER - 2)) + 1
    elif side == 2: # right
        x = DEFAULT_BATTLEFIELD_COLUMNS_NUMBER - 1
        y = (randi() % (DEFAULT_BATTLEFIELD_ROWS_NUMBER - 2)) + 1
    elif side == 3: # bottom
        y = DEFAULT_BATTLEFIELD_ROWS_NUMBER - 1
        x = (randi() % (DEFAULT_BATTLEFIELD_COLUMNS_NUMBER - 2)) + 1

    var result_position = Vector2(x, y)

    if to_keep_distance.distance_squared_to(Vector2()) > 0:
        if to_keep_distance.distance_squared_to(result_position) < 2:
            return self.get_random_border_position(to_keep_distance)

    return result_position



#####
# Listeners:
#####
func _on_SaveGameButton_pressed():
    self.save_game()

func _on_LoadGameButton_pressed():
    self.load_game()

func _on_Reset_Game_pressed():
    self.reset_game()

func _on_SelectionPreview_pressed():
    target_building = ""
    update_building_preview(target_building)

func on_tower_selected(tower: Node2D):
    if target_building == CONSTRUCTION_TYPE_DESTROY:
        #tower.queue_free()
        self.remove_construction(tower.position)
    else:
        tower.toggle_radius_visibility()

# @TODO use same construction types in building menus as in battlefield scene
func _on_BuildingMenu_building_target_was_selected(construction_type):
    if construction_type == 0:
        target_building = CONSTRUCTION_TYPE_DESTROY
    elif construction_type == 1:
        target_building = CONSTRUCTION_TYPE_TOWER_BASEMENT
    elif construction_type == 2:
        target_building = CONSTRUCTION_TYPE_BALLISTA_TOWER
    elif construction_type == 3:
        target_building = CONSTRUCTION_TYPE_CANNON_TOWER
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

    var mobs_for_level = self.game_data.game_level
    if mobs_for_level > 20: mobs_for_level = 20
    var bonus_mobs = (randi() % (self.game_data.game_level + 2)) % 10

    current_wave_counter = mobs_for_level + bonus_mobs
    $mob_create_timer.start()


func _on_BattleField_gui_input(event):
    if event is InputEventMouseButton:
        var battleFieldRect = $BattleField.get_rect()
        if event.button_index == BUTTON_LEFT:
            if event.is_pressed():
                if (not self.is_cell_available_for_building(event.position - battleFieldRect.position) and
                    target_building != CONSTRUCTION_TYPE_DESTROY):
                    return

                if target_building == CONSTRUCTION_TYPE_DESTROY:
                    self.remove_construction(event.position - battleFieldRect.position)
                elif target_building != "":
                    self.on_try_build_construction(event.position - battleFieldRect.position, target_building)

                # target_building = ""
                self.update_building_preview(target_building)

        if event.button_index == BUTTON_RIGHT:
            pass

    elif event is InputEventMouseMotion:
        pass

# remove mobs when they reach the exit
func _on_ExitArea_area_entered(area: Area2D) -> void:
    if not "entity_class" in area:
        return

    if area.entity_class == "Enemy":
        area.queue_free()
        self.game_data.score -= 10
        update_score_label()

func on_kill_mob():
    self.game_data.gold += randi() % 2 + 1
    self.game_data.score += 1 * self.game_data.game_level
    check_and_update_game_level()
    update_score_label()

func on_try_build_construction(position, construction_type):
    var tower_cost: int = CONSTRUCTION_TYPES_COSTS[construction_type]

    if self.game_data.gold < tower_cost:
        return

    var cell_position = main_tile_map.world_to_map(position)
    if self.game_data.battlefield_data[cell_position.y][cell_position.x].type != CONSTRUCTION_TYPE_GRASS:
        return

    self.game_data.battlefield_data[cell_position.y][cell_position.x].type = construction_type
    update_battle_field_view(self.game_data.battlefield_data)

    self.game_data.gold -= tower_cost
    update_score_label()

func _on_mob_create_timer_timeout():
    if current_wave_counter == 0:
        $mob_create_timer.stop()
    else:
        current_wave_counter -= 1
        create_entity()
