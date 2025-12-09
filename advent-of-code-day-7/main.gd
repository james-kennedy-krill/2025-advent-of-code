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

func solve_part_two():
	var line_paths: Dictionary = {}

	var lines = instructions.duplicate()
	var left_or_right: int
	
	for o in range(0, 1000000):
		var line_path = ""
		var map = instructions.duplicate()
		var line_toggles: Array[bool] = []
		line_toggles.resize(instructions[0].length())
		var next_line_toggles = line_toggles.duplicate()
		
		for row in lines.size():
			line_toggles = next_line_toggles.duplicate()
			left_or_right = randi_range(1, 2)
			for i in lines[row].length():
				if lines[row][i] == ".":
					# if this column was on, replace it with |
					if line_toggles[i] == true:
						map[row][i] = "|"
				elif lines[row][i] == "S":
					next_line_toggles[i] = true
				else:
					if lines[row][i] == "^":
						if line_toggles[i] != true:
							continue
						# turn off the splits in this column
						next_line_toggles[i] = false
						# turn on the splits to the side
						if i > 0 and left_or_right == 1:
							map[row][i-1] = "|"
							next_line_toggles[i-1] = true
							line_path += "1"
						if i < lines[row].length() - 1 and left_or_right == 2:
							map[row][i+1] = "|"
							next_line_toggles[i+1] = true
							line_path += "2"
		
		if debug:
			for row in map:
				print(row)
	
		line_paths.set(line_path, true)
			
	if debug:
		print(line_paths)
	print(line_paths.size())
