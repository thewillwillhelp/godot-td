extends Node

signal swipe_is_happened
signal screen_click(event)

var swipe_is_started: bool = false
var _screen_pressed: bool = false
var start_position: Vector2
var move_position: Vector2

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            if event.is_pressed():
                self._screen_pressed = true
                self.swipe_is_started = false
                self.start_position = event.position
                self.move_position = event.position
            else:
                self._screen_pressed = false
                emit_signal("screen_click", event)

    if event is InputEventMouseMotion:
        if not self._screen_pressed:
            return

        if Vector2().distance_squared_to(event.position - self.start_position) > 0:
            emit_signal("swipe_is_happened", event.position - self.move_position)
            self.move_position = event.position
            self.swipe_is_started = true

func is_screen_moved() -> bool:
    return self.swipe_is_started
