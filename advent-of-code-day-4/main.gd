extends Node2D

enum Part {
	ONE,
	TWO
}
@export var part: Part = Part.ONE
@export var paper_roll_character: String = "@"
@export var empty_space_character: String = "."
@export var max_adjacent_rolls := 4
@export_file("*.txt") var input_file_path: String

var instructions := []
var factory := {}
var factory_rows := 0
var factory_columns := 0

var total_rolls_accessible := 0
var total_rolls_removed := 0

func _ready() -> void:
	instructions = InstructionLoader.load_instructions(input_file_path)
	build_factory()
	
	factory_rows = instructions.size()
	factory_columns = instructions[0].length()
	
	print("Rows: ", factory_rows)
	print("Cols: ", factory_columns)

	if part == Part.ONE:
		call_deferred("run_part_1")
	elif part == Part.TWO:
		call_deferred("run_part_2")
	else:
		pass

func build_factory() -> void:
	for row_i in instructions.size():
		for cell_i in instructions[row_i].length():
			set_cell(Vector2i(row_i, cell_i), instructions[row_i][cell_i])

func run_part_1() -> void:
	for r in factory_rows:
		for c in factory_columns:
			var pos := Vector2i(r, c)
			var cell_value = get_cell(pos)
			if cell_value == paper_roll_character:
				#print("-- Checking: ", pos)
				if check_forklift_access(Vector2i(r, c)):
					total_rolls_accessible += 1
					
	print("Total: ", total_rolls_accessible)
	
func run_part_2() -> void:
	var total_remaining_accessible_rolls = count_and_remove_accessible_rolls()
	while total_remaining_accessible_rolls > 0:
		total_remaining_accessible_rolls = count_and_remove_accessible_rolls()
		
	print("Total removed: ", total_rolls_removed)

func count_and_remove_accessible_rolls() -> int:
	var accessible_rolls := 0
	for r in factory_rows:
		for c in factory_columns:
			var pos := Vector2i(r, c)
			var cell_value = get_cell(pos)
			if cell_value == paper_roll_character:
				if check_forklift_access(pos):
					accessible_rolls += 1
					set_cell(pos, ".")
	
	total_rolls_removed += accessible_rolls
	return accessible_rolls


func set_cell(pos: Vector2i, value: String) -> void:
	factory[pos] = value

func get_cell(pos: Vector2i) -> String:
	return factory.get(pos, "")

func check_forklift_access(pos: Vector2i) -> bool:
	var adjacent_rolls = count_adjacent(pos)
	#print("---- adjacent rolls: ", adjacent_rolls)
	return adjacent_rolls < max_adjacent_rolls

func count_adjacent(pos: Vector2i) -> int:
	var adjacent_rolls = 0
	# 1. top
	if check_adjacent(pos, Vector2i(-1, 0)):
		adjacent_rolls += 1
	
	# 2. top-right
	if check_adjacent(pos, Vector2i(-1, 1)):
		adjacent_rolls += 1
	
	# 3. right
	if check_adjacent(pos, Vector2i(0, 1)):
		adjacent_rolls += 1
	
	# 4. bottom-right
	if check_adjacent(pos, Vector2i(1, 1)):
		adjacent_rolls += 1
	
	# 5. bottom
	if check_adjacent(pos, Vector2i(1, 0)):
		adjacent_rolls += 1
	
	# 6. bottom-left
	if check_adjacent(pos, Vector2i(1, -1)):
		adjacent_rolls += 1
	
	# 7. left
	if check_adjacent(pos, Vector2i(0, -1)):
		adjacent_rolls += 1
	
	# 8. top left
	if check_adjacent(pos, Vector2i(-1, -1)):
		adjacent_rolls += 1
	
	#print("Adjacent rolls = ", adjacent_rolls)
	
	return adjacent_rolls
	
func check_adjacent(pos: Vector2i, dir: Vector2i) -> bool:
	var new_location = pos - dir
	#print("--- Checking: ", new_location)
	
	# Check out of bounds. 
	# If the position we are checking is out of bounds, return false 
	# (there is no paper rolls there)
	
	# check top out of bounds
	if new_location.y < 0:
		return false
	# check left out of bounds
	if new_location.x < 0:
		return false
	# check bottom out of bounds
	if new_location.y >= factory_rows:
		return false
	# check right out of bounds
	if new_location.x >= factory_columns:
		return false
		
	#print("Character at location: ", get_cell(new_location))	
	
	return get_cell(new_location) == paper_roll_character
	
