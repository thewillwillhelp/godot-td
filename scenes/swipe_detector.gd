extends Node

signal swipe_is_happened
signal screen_click(event)

var swipe_is_started: bool = false
var _swipe_is_stopped: bool = true
var start_position: Vector2
var end_position: Vector2

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            if event.is_pressed():
                self._swipe_is_stopped = false
                self.start_position = event.position
            else:
                self._swipe_is_stopped = true
                emit_signal("screen_click", event)
                $Timer.start()
                # self.end_position = event.position
                # self.check_is_swipe_happened()

    if event is InputEventMouseMotion:
        if not self._swipe_is_stopped:
            if not self.swipe_is_started:
                # self.swipe_is_started = true
                $Timer.start()
            else:
                emit_signal("swipe_is_happened", event.position - self.start_position)
                self.start_position = event.position

# tricky logic
# do not allow building right after releasing input

func _on_Timer_timeout():
    if self._swipe_is_stopped:
        self.swipe_is_started = false
    else:
        self.swipe_is_started = true
