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
	
	var grid = instructions.map(func(row): return row.split(""))
	
	var rows = grid.size()
	var cols = grid[0].size()

	var numbers = []
	var total := 0
	var op = ""

	for col in range(cols - 1, -1, -1):     # right → left
		# start building number for the column
		var number = ""
		for row in range(rows):  
			if debug:            # top → bottom
				print ("row: ", row, " | col: ", col)
			
			var value = grid[row][col]
			
			if debug: 
				print (" = ", value)
				
			if value == " ":
				continue
			elif value == "*" or value == "+":
				op = value
			else:
				number += value
		
		if debug:
			print("NUMBER: ", number)
			
		if number == "":
				continue
		else:
			numbers.append(int(number))
			
		# if we have an operator, we are at the end of the numbers
		# Calculate and reset
		if op != "":
			
			if debug: 
				print("OP: ", op)
				print("NUMBERS: ", numbers)
				
			if op == "*":
				total = 1
				for num in numbers:
					total *= num
			elif op == "+":
				for num in numbers:
					total += num
			
			grand_total += total
			numbers = []
			total = 0
			op = ""
	
	print("--- ANSWER: ", grand_total, " -----")
