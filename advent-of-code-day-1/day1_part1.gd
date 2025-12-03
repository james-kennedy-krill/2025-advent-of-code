extends Node3D

enum Speed { SLOW, FAST, INSTANT }

@export var speed: Speed
@export var debug := false

@onready var dial: MeshInstance3D = $lock/Dial
@onready var text_edit: TextEdit = $CanvasLayer/UI/Panel/VBoxContainer/TextEdit
@onready var button: Button = $CanvasLayer/UI/Panel/VBoxContainer/Button
@onready var password_label: Label = $CanvasLayer/UI/Password
@onready var current = $CanvasLayer/UI/HBoxContainer/Current

# The text block to process
var input_text: String = ""

# The current location: 0-99
var previous_current_value: int = 0
var current_value: int = 50

# The final pasword result
var password: int = 0

var speed_value: float = 0.2

# Called when the node enters the scene tree for the first time.
func _ready():
	if speed == Speed.SLOW:
		speed_value = 0.2
	elif speed == Speed.FAST:
		speed_value = 0.05
	else:
		speed_value = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if previous_current_value != current_value:
		if current_value == 0:
			password += 1
		previous_current_value = current_value
		current.text = str(current_value)
		var degrees = _calculate_degrees_from_number(current_value)
		dial.rotation_degrees.z = degrees
		#_rotate_dial(degrees)
		
	password_label.text = str(password)

func _rotate_dial(degrees: float) -> void:
	var start := dial.rotation_degrees.z
	var end := start + degrees
	var tween := get_tree().create_tween()
	tween.tween_property(dial, "rotation_degrees:z", end, speed_value - 0.01).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_text_edit_text_changed():
	_reset_data()

func _on_button_pressed():
	input_text = text_edit.text
	_process_input()

func _calculate_degrees_from_number(val: int) -> float:
	var ratio = val / 100.0
	var degrees = -360 * ratio
	return degrees
	
func _reset_data() -> void:
	input_text = ""
	password_label.text = "-"
	
func _process_input() -> void:
	var instructions: PackedStringArray = _extract_instructions(input_text)
	
	# for each instruction, handle left or right
	for instruction in instructions:
		if instruction[0] == "L":
			var num = int(instruction.get_slice("L", 1))
			_update_value(num, "-")
		elif instruction[0] == "R":
			var num = int(instruction.get_slice("R", 1))
			_update_value(num, "+")
			
		await get_tree().create_timer(speed_value).timeout
	
func _extract_instructions(text_blob: String) -> PackedStringArray:
	var normalized := text_blob.replace("\r\n", "\n").replace("\r", "\n")
	return normalized.split("\n")
	
func _update_value(num: int, opp: String) -> void:
	if num > 100:
		num = num % 100
	if opp == "-":
		var new_value = current_value - num
		if new_value < 0:
			current_value = 100 + new_value
		else:
			current_value = new_value
	elif opp == "+":
		var new_value = current_value + num
		if new_value > 99:
			current_value = new_value - 100
		else:
			current_value = new_value
