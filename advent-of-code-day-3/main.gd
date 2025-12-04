extends Node3D

@onready var batteries_container: Node3D = $battery_voltage/Batteries
@onready var displays: Node3D = $battery_voltage/Displays
@onready var labels_container: Node3D = $battery_voltage/Labels
@onready var camera_rig: Node3D = $CameraRig

@export var focus_time: float = 0.0     # seconds to move/rotate to each label
@export var pause_time: float = 0.0     # seconds to pause on each label
@export var step_distance: float = 0.085  # meters per label stepl

var input_file_path := "res://input.txt"
#var input_file_path := "res://sample_input.txt"
var input_lines: Array[String]
var labels: Array[Label3D]= []
var batteries: Array[MeshInstance3D] = []
var _start_position: Vector3

var current_line_first_index := 0
var current_line_second_index := 0

var part_2_current_line_indexes: Array[int] = []
var part_2_current_line_value: String = ""

enum Part { ONE, TWO }
var part_1_or_2: Part = Part.ONE

var total := 0

func _ready() -> void:
	for child in labels_container.get_children():
		var label := child as Label3D
		if label != null:
			labels.append(label)
	for child in batteries_container.get_children():
		var battery := child as MeshInstance3D
		if battery != null:
			batteries.append(battery)
	input_lines = load_instructions(input_file_path)
	_start_position = camera_rig.global_position

func start() -> void:
	if input_lines == null or input_lines.size() == 0:
		return
	_load_lines()

func _load_lines() -> void:
	for i in range(0, input_lines.size()):
		var line := input_lines[i]
		print("\n")
		print("-------- LINE ", i+1, " ---------")
		print("Line: ", line)
		await _load_line(line)

func _load_line(line: String) -> void:
	for voltage_i in line.length():
		var label: Label3D = labels[voltage_i]
		var battery: MeshInstance3D = batteries[voltage_i]
		label.text = line[voltage_i]
		label.modulate = Color.WHITE
		battery.rotation_degrees.z = 35.4
	if part_1_or_2 == Part.ONE:
		current_line_first_index = 0
		current_line_second_index = 0
		await _evaluate_line(line)
	elif part_1_or_2 == Part.TWO:
		part_2_current_line_indexes = []
		part_2_current_line_value = ""
		await _evaluate_line_2(line)
	else:
		return
	
func _evaluate_line(line: String) -> void:
	_calculate_line(line)
	await _focus_labels_sequence(line.length())
	

func _calculate_line(line: String) -> void:
	# the first number can never be the last number, even if it's the biggest
	for i in line.length()-1:
		current_line_first_index = i if int(line[i]) > int(line[current_line_first_index]) else current_line_first_index
	current_line_second_index = current_line_first_index + 1
	for i in range(current_line_second_index, line.length()):
		current_line_second_index = i if int(line[i]) > int(line[current_line_second_index]) else current_line_second_index
	
	# Compute voltage
	var this_voltage: String = line[current_line_first_index] + line[current_line_second_index]
	print("This voltage: ", this_voltage)
	# Increment total
	total += int(this_voltage)
	print("New Total: ", total)
	

func _focus_labels_sequence(line_length: int) -> void:
	# Move through each label position by sliding to the right
	print("first index ", current_line_first_index, " = ", labels[current_line_first_index].text)
	print("second index ", current_line_second_index, " = ", labels[current_line_second_index].text)
	for i in range(line_length):

		var target_pos := _start_position + camera_rig.global_basis.x * step_distance * float(i)
		labels[i].modulate = Color.ORANGE_RED
		await _tween_camera_to_position(target_pos)
		await get_tree().create_timer(pause_time).timeout
		if current_line_first_index == i or current_line_second_index == i:
			await _animate_battery(i)
			labels[i].modulate = Color.WEB_GREEN
		else:
			labels[i].modulate = Color.WHITE

	# Return to original spot
	await _tween_camera_to_position(_start_position)

# PART 2
func _evaluate_line_2(line: String) -> void:
	_calculate_line_2(line)
	await _focus_labels_sequence_2(line.length())
	

func _calculate_line_2(line: String) -> void:
	# Get the highest number that is within 12 spots of the end
	part_2_current_line_indexes.append(_get_next_highest_number_index(line, 0, line.length() - 11))
	#print("Part two first number: ", line[part_2_current_line_indexes[0]])
	while part_2_current_line_indexes.size() < 12:
		var this_index = part_2_current_line_indexes.size()
		var remaining_spots = 12-this_index
		#print("remaining spots ", remaining_spots)
		#print("this index: ", this_index)
		if this_index >= 0 and this_index == part_2_current_line_indexes.size():
			part_2_current_line_indexes.append(-1)
		part_2_current_line_indexes[this_index] = _get_next_highest_number_index(line, part_2_current_line_indexes[this_index-1]+1, (line.length()-remaining_spots)+1)
		#for i in range(part_2_current_line_indexes[0]+1, line.length()):
			 #i if int(line[i]) > int(line[current_line_second_index]) else current_line_second_index
		
	print("result: ", part_2_current_line_indexes)
	var this_voltage: String = "".join( part_2_current_line_indexes.map(func(i): return line[i]))
	part_2_current_line_value = this_voltage
	print("This voltage: ", this_voltage)
	total += int(this_voltage)
	print("New Total: ", total)

func _get_next_highest_number_index(line: String, start_i: int, end_i: int) -> int:
	#print("checking range: ")
	#print("--start: ", start_i)
	#print("--end: ", end_i)
	var next_highest_number_index = start_i
	for i in range(start_i, end_i):
		next_highest_number_index = i if int(line[i]) > int(line[next_highest_number_index]) else next_highest_number_index
	return next_highest_number_index

func _focus_labels_sequence_2(line_length: int) -> void:
	# Move through each label position by sliding to the right
	#print("part_2_current_line_value: ", part_2_current_line_value)
	for i in range(line_length):

		var target_pos := _start_position + camera_rig.global_basis.x * step_distance * float(i)
		labels[i].modulate = Color.ORANGE_RED
		await _tween_camera_to_position(target_pos)
		await get_tree().create_timer(pause_time).timeout
		if i in part_2_current_line_indexes:
			await _animate_battery(i)
			labels[i].modulate = Color.WEB_GREEN
		else:
			labels[i].modulate = Color.WHITE

	# Return to original spot
	await _tween_camera_to_position(_start_position)


func _animate_battery(i: int) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(batteries[i], "rotation_degrees:z", 0.0, focus_time)
	await tween.finished

func _tween_camera_to_position(target_pos: Vector3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(camera_rig, "global_position", target_pos, focus_time)
	await tween.finished

func load_instructions(path: String) -> Array[String]:
	var results: Array[String] = []

	# Check file exists first
	if not FileAccess.file_exists(path):
		push_error("load_instructions: File does not exist → %s" % path)
		return results

	# Open file
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("load_instructions: Could not open file → %s" % path)
		return results

	# Read line-by-line
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line != "":
			results.append(line)

	return results



func _on_button_pressed() -> void:
	part_1_or_2 = Part.ONE
	start()


func _on_button_2_pressed() -> void:
	part_1_or_2 = Part.TWO
	start()
