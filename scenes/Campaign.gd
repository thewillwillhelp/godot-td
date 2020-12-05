extends Node2D

const BattleFieldScene: PackedScene = preload("res://scenes/BattleFieldScene.tscn")
const utils: GDScript = preload("res://utils/Utils.gd")

onready var battle_field_scene = BattleFieldScene.instance()
const max_level = 5
var current_level := 1
var previous_game_data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    self.start_campaign()

func start_campaign():
    self.start_campaign_level()

func start_campaign_level():
    var campaign_level = $Levels.get_node("Level%d" % current_level)
    var level_data = utils.merge_dictionaries(self.prepare_level_data(campaign_level.default_data), previous_game_data)
    # level_data.max_waves = 0 # for debug purposes
    battle_field_scene = BattleFieldScene.instance()
    battle_field_scene.start_automatically = false
    self.add_child(battle_field_scene)
    self.move_child(battle_field_scene, 1)
    battle_field_scene.start_game(true, level_data)
    battle_field_scene.connect("waves_finished", self, "finish_level")

func finish_level():
    previous_game_data = utils.merge_dictionaries_by_fields({}, battle_field_scene.game_data, ["score", "gold", "lives"])
    current_level += 1

    if self.current_level > self.max_level:
        $WinMessage.text = "You win!\nYour score:\n%d" % previous_game_data.score
        $WinMessage.visible = true
        return

    self.remove_child(battle_field_scene)
    self.start_campaign_level()


func prepare_level_data(level_data):
    level_data.battlefield_data = self.get_battlefield_data(level_data.battlefield_raw_data)
    return level_data

func get_battlefield_data(input_data: Array) -> Array:
    var battlefield_data := []
    for i in range(0, len(input_data)):
        battlefield_data.append([])
        for j in range(0, len(input_data[i])):
            var cell_object = { "type": "GRASS" }
            if input_data[i][j] == 0:
                cell_object.type = "STONE WALL"
            if input_data[i][j] == 2:
                cell_object.type = "BARRICADE"
            if input_data[i][j] == 3:
                cell_object.type = "TOWER BASEMENT"
            if input_data[i][j] == 4:
                cell_object.type = "BALLISTA TOWER"
            if input_data[i][j] == 5:
                cell_object.type = "CANNON TOWER"

            battlefield_data[i].append(cell_object)

    return battlefield_data
