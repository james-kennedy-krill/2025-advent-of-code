extends Node3D

@onready var display_label: Label3D = $Display/north_pole_display/DisplayLabel
@onready var cylinder: MeshInstance3D = $Display/north_pole_display/Cylinder
@onready var puzzle_input: TextEdit = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/PuzzleInput
@onready var status_input: TextEdit = $CanvasLayer/Panel/HBoxContainer/StatusInput
@onready var invalid_ids_input: TextEdit = $CanvasLayer/Panel/HBoxContainer/InvalidIdsInput

@export var glow_amount := 6.0
@export var red_glow_time := 0.8
@export var green_glow_time := 0.05

var invalid_ids: Array[int]
var red_material: Material
var green_material: Material

var started = false

func _ready() -> void:
	if cylinder != null:
		red_material = cylinder.get_surface_override_material(2)
		green_material = cylinder.get_surface_override_material(3)
		
func _process(_delta: float) -> void:
	if started:
		status_input.text = "\n".join(invalid_ids)
		invalid_ids_input.text = str(invalid_ids.reduce(func(a, b): return a + b, 0))

func _solve_puzzle_input() -> void:
	var puzzle_input_string = puzzle_input.text
	
	if puzzle_input_string != "":
		var puzzle_input_strings = puzzle_input_string.replace(" ","") \
			.replace("\r", "").replace("\n", "") \
			.split(",",false)
		for num_range in puzzle_input_strings:
			var pre_test = true
			var start_end = num_range.split("-", false, 1)
			if start_end[0][0] == "0":
				pre_test = false
			if start_end[1][0] == "0":
				pre_test = false
			var start = int(start_end[0])
			var end = int(start_end[1])
			for num in range(start, end+1):
				var is_valid = _test_id(num) && pre_test
				display_label.text = str(num)
				if is_valid:
					if green_material and green_material is StandardMaterial3D:
						var gm := green_material as StandardMaterial3D
						var original_emission_energy = gm.emission_energy_multiplier
						gm.emission_energy_multiplier = glow_amount
						await get_tree().create_timer(green_glow_time).timeout
						gm.emission_energy_multiplier = original_emission_energy
				else:
					invalid_ids.append(num)
					if red_material and red_material is StandardMaterial3D:
						var rm := red_material as StandardMaterial3D
						var original_emission_energy = rm.emission_energy_multiplier
						rm.emission_energy_multiplier = glow_amount
						await get_tree().create_timer(red_glow_time).timeout
						rm.emission_energy_multiplier = original_emission_energy
				

		display_label.text = "finished"
		
func _test_id(id: int) -> bool:
	var result := true
	var id_string = str(id)
	var id_string_length = id_string.length()
	# loop through each number in the id
	for i in range(id_string_length):
		if _test_number(int(id_string.substr(0, i+1)), int(id_string)):
			print("returned false: ", id_string.substr(0, i+1))
			result = false
			break
			
	return result

func _test_number(target: int, full: int) -> bool:
	return str(full) == str(target) + str(target)

func _on_button_pressed() -> void:
	started = true
	_solve_puzzle_input()
