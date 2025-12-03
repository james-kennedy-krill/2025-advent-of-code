extends Node3D

@onready var display_label: Label3D = $Display/north_pole_display/DisplayLabel
@onready var cylinder: MeshInstance3D = $Display/north_pole_display/Cylinder
@onready var puzzle_input: TextEdit = $CanvasLayer/Panel/HBoxContainer/VBoxContainer/PuzzleInput
@onready var status_input: TextEdit = $CanvasLayer/Panel/HBoxContainer/StatusInput
@onready var invalid_ids_input: TextEdit = $CanvasLayer/Panel/HBoxContainer/InvalidIdsInput

@export var glow_amount := 6.0
@export var red_glow_time := 0.1
@export var green_glow_time := 0.00001

var invalid_ids: Array[int]
var red_material: Material
var green_material: Material

var running = false

func _ready() -> void:
	if cylinder != null:
		red_material = cylinder.get_surface_override_material(2)
		green_material = cylinder.get_surface_override_material(3)
		
func _process(_delta: float) -> void:
	if running:
		status_input.text = "\n".join(invalid_ids)
		call_deferred("_update_solution_text")

func _update_solution_text() -> void:
	invalid_ids_input.text = str(invalid_ids.reduce(func(a, b): return a + b, 0))

func _solve_part_1() -> void:
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
			if start_end[0].length() % 2 != 0 and start_end[1].length() % 2 != 0:
				continue
			for num in range(start, end+1):
				if str(num).length() % 2 != 0:
					continue
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
		running = false
		
func _test_id(id: int) -> bool:
	var result := true
	var id_string = str(id)
	var id_string_length = id_string.length()
	# loop through each number in the id
	for i in range(id_string_length):
		if _test_number(int(id_string.substr(0, i+1)), int(id_string)):
			result = false
			break
			
	return result

func _test_number(target: int, full: int) -> bool:
	return str(full) == str(target) + str(target)
	
	

# PART 2
func _solve_part_2() -> void:
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
				var is_valid = _test_id_2(num) && pre_test
				display_label.text = str(num)
				if is_valid:
					if green_material and green_material is StandardMaterial3D:
						var gm := green_material as StandardMaterial3D
						var original_emission_energy = gm.emission_energy_multiplier
						gm.emission_energy_multiplier = glow_amount
						#await get_tree().create_timer(green_glow_time).timeout
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
		running = false
		
func _test_id_2(id: int) -> bool:
	var result := true
	var id_string = str(id)
	var id_string_length = id_string.length()
	var half_string_length = id_string_length/2.0
	# loop through each number in the id (half way)
	for i in range(ceili(id_string_length/2.0)):
		if _test_number_2(int(id_string.substr(0, i+1)), int(id_string), i):
			result = false
			break
			
	return result

func _test_number_2(target: int, full: int, current_index: int) -> bool:
	var target_length = str(target).length()
	var full_length = str(full).length()
	var remaineder_length = full_length - target_length
	var repeated_times: int = remaineder_length / target_length
	var test: String = str(target) + str(target).repeat(repeated_times)

	return full_length > 1 && str(full) == test

func _on_button_pressed() -> void:
	running = true
	_solve_part_1()

func _on_part_2_pressed() -> void:
	running = true
	_solve_part_2()
