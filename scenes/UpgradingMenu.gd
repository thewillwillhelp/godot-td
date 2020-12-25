extends Node2D

signal destruction_was_selected
signal damage_booster_was_selected
signal speed_booster_was_selected
signal range_booster_was_selected

var construction: Area2D
var game_data: Node

func set_target_construction(construction: Area2D, game_data: Node) -> void:
    self.game_data = game_data
    self.construction = construction
    self._update_view()

func set_visibility(visible):
    self.visible = visible
    if not visible:
        self.construction = null
        self.game_data = null

func _ready():
    set_process(false)

func _update_view() -> void:
    if not self.construction:
        return

    if self.construction.attack_speed_booster == 0:
        $SpeedBooster/Filter.visible = true
    else:
        $SpeedBooster/Filter.visible = false

    if self.construction.damage_booster == 0:
        $DamageBooster/Filter.visible = true
    else:
        $DamageBooster/Filter.visible = false

    if self.construction.range_booster == 0:
        $RangeBooster/Filter.visible = true
    else:
        $RangeBooster/Filter.visible = false


func _on_damage_booster_pressed():
    self.construction.upgrade("damage", self.game_data)
    self._update_view()


func _on_range_booster_pressed():
    self.construction.upgrade("range", self.game_data)
    self._update_view()


func _on_speed_booster_pressed():
    self.construction.upgrade("attack_speed", self.game_data)
    self._update_view()
