extends Node3D

@export var deg_per_sec := 9.0
@export var debug := false

@onready var dial: Area3D = $lock/Dial
@onready var text_edit: TextEdit = $CanvasLayer/UI/Panel/VBoxContainer/TextEdit
@onready var button: Button = $CanvasLayer/UI/Panel/VBoxContainer/Button
@onready var password_label: Label = $CanvasLayer/UI/Password
@onready var current = $CanvasLayer/UI/HBoxContainer/Current
@onready var progress_bar: ProgressBar = $CanvasLayer/UI/ProgressBar

# The text block to process
var input_text: String = ""

# The final pasword result
var password: int = 0

var START_NUMBER := 50
var start_degrees: float = 180.0
var progress := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	dial.rotate_z(deg_to_rad(start_degrees))
	password = 0

func _on_text_edit_text_changed():
	_reset_data()

func _on_button_pressed():
	input_text = text_edit.text
	_process_input()
	
func _reset_data() -> void:
	dial.rotation_degrees.z = start_degrees
	input_text = ""
	password = 0
	password_label.text = "-"
	progress_bar.value = 0.0
	progress_bar.max_value = 100.0
	
func _process_input() -> void:
	var instructions: PackedStringArray = _extract_instructions(input_text)
	
	var dial_value: int = START_NUMBER
	progress_bar.max_value = instructions.size()
	
	# for each instruction, handle left or right
	for instruction in instructions:
		var num: int
		var step: int
		if instruction == "":
			continue
		if instruction[0] == "L":
			num = int(instruction.get_slice("L", 1))
			step = -1
		elif instruction[0] == "R":
			num = int(instruction.get_slice("R", 1))
			step = 1
		
		print("Num: ", num)
		current.text = str(num)
		for _i in range(num):
			dial_value = (dial_value + step) % 100
			dial.rotation_degrees.z = _value_to_degrees(dial_value, step)
			print("Dial Value: ", dial_value)
			if dial_value == 0:
				password += 1
		
	password_label.text = str(password)

func compute_tween_duration(degrees: float) -> float:
	return abs(degrees) / deg_per_sec


func _extract_instructions(text_blob: String) -> PackedStringArray:
	var normalized := text_blob.replace("\r\n", "\n").replace("\r", "\n")
	return normalized.split("\n")
	
func _value_to_degrees(num: int, step: int) -> float:
	var degrees = (num / 100.0) * (step * 360.0) 
	return degrees
