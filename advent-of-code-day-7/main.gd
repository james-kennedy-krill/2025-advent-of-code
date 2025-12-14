extends Node3D

enum Part {
	ONE,
	TWO
}
@export var part: Part = Part.ONE
@export_enum("Use Sample", "Use Input") var data_to_use := "Use Sample"
@export_file("*.txt") var sample_input_file: String
@export_file("*.txt") var input_file: String
@export var debug := false


var instructions := []
var grand_total := 0

var total_paths = 0

func _ready() -> void:
	var input_file_path = sample_input_file if data_to_use == "Use Sample" else input_file
	instructions = InstructionLoader.load_instructions(input_file_path)
	
	if part == Part.ONE:
		solve_part_one()
	if part == Part.TWO:
		solve_part_two()
	
func solve_part_one():
	var line_toggles: Array[bool] = []
	line_toggles.resize(instructions[0].length())
	var next_line_toggles = line_toggles.duplicate()
	
	var lines = instructions.duplicate()
	
	for row in lines.size():
		line_toggles = next_line_toggles.duplicate()
		for i in lines[row].length():
			if lines[row][i] == ".":
				# if this column was on, replace it with |
				if line_toggles[i] == true:
					instructions[row][i] = "|"
			elif lines[row][i] == "S":
				next_line_toggles[i] = true
			else:
				if lines[row][i] == "^":
					if line_toggles[i] == true:
						grand_total += 1
					# turn off the splits in this column
					next_line_toggles[i] = false
					# turn on the splits to the side
					if i > 0:
						instructions[row][i-1] = "|"
						next_line_toggles[i-1] = true
					if i < lines[row].length() - 1:
						instructions[row][i+1] = "|"
						next_line_toggles[i+1] = true
	
	for row in instructions:
		print(row)
			
	
	print(grand_total)

var _memo: Dictionary = {} # key: Vector2i(row, col) -> int

func solve_part_two():
	_memo.clear()
	var start_col :int = instructions[0].findn("S")
	total_paths = count_paths(instructions, 0, start_col)
	print(total_paths)

func count_paths(lines: Array[String], row: int, col: int) -> int:
	var line_size = lines.size()
	
	# end
	if row >= line_size:
		return 1

	# bounds (use current row width)
	var w := lines[row].length()
	if col < 0 or col >= w:
		return 1

	var key := Vector2i(row, col)
	if _memo.has(key):
		return _memo[key]

	# scan down to first '^'
	for r in range(row, line_size):
		var line := lines[r]
		if col < 0 or col >= line.length():
			_memo[key] = 1
			return 1

		if line[col] == "^":
			var res := count_paths(lines, r + 1, col - 1) + count_paths(lines, r + 1, col + 1)
			_memo[key] = res
			return res

	# no more splits
	_memo[key] = 1
	return 1
