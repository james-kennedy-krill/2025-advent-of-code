extends Camera2D

@export var min_zoom: float = 0.1      # how far you can zoom OUT  (smaller number = see more world)
@export var max_zoom: float = 10.0     # how far you can zoom IN   (bigger number = see less world)
@export var zoom_step: float = 0.1     # ~10% per mouse wheel tick
@export var pan_button: MouseButton = MOUSE_BUTTON_MIDDLE  # can switch to LEFT/RIGHT if you want

var _zoom_level: float = 1.0
var _dragging: bool = false


func _ready() -> void:
	# In Godot 4: Camera2D uses `enabled` + make_current(), not `current`.
	enabled = true                       # usually true by default, but explicit is nice
	make_current()                       # ensure this is the active 2D camera

	_zoom_level = zoom.x                 # assume x == y


func _unhandled_input(event: InputEvent) -> void:
	# --- Mouse wheel zoom ---
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			# Wheel up = zoom IN (closer)
			_change_zoom(true)
			get_viewport().set_input_as_handled()

		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			# Wheel down = zoom OUT (farther)
			_change_zoom(false)
			get_viewport().set_input_as_handled()

		# --- Start/stop panning with middle mouse (or whatever pan_button is) ---
		elif mb.button_index == pan_button:
			_dragging = mb.pressed
			get_viewport().set_input_as_handled()

	# --- Mouse drag panning ---
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		# Move opposite to mouse direction; multiply by zoom so pan speed feels consistent
		global_position -= mm.relative * zoom
		get_viewport().set_input_as_handled()


func _change_zoom(zoom_in: bool) -> void:
	# In Camera2D:
	#   smaller zoom value  -> zoom OUT (see more)
	#   larger  zoom value  -> zoom IN  (see less)
	#
	# So:
	#   - zoom IN  -> multiply by > 1
	#   - zoom OUT -> divide   by > 1

	var factor := 1.0 + zoom_step

	if zoom_in:
		_zoom_level *= factor               # zoom in = increase zoom value
	else:
		_zoom_level /= factor               # zoom out = decrease zoom value

	_zoom_level = clamp(_zoom_level, min_zoom, max_zoom)
	zoom = Vector2.ONE * _zoom_level
