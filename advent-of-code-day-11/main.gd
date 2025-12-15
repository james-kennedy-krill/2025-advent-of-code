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
var devices: Dictionary = {}

func _ready() -> void:
	var input_file_path = sample_input_file if data_to_use == "Use Sample" else input_file
	instructions = InstructionLoader.load_instructions(input_file_path)
	
	if debug:
		print("Instructions: \n", instructions)
		
	for line in instructions:
		var line_split = line.split(":")
		var device = line_split[0]
		var connected_devices = line_split[1].strip_edges().split(" ")
		devices.set(device, connected_devices)
		
	if debug:
		print("\nDevices: \n", devices)
	
	if part == Part.ONE:
		call_deferred("solve_part_one")
	if part == Part.TWO:
		call_deferred("solve_part_two")
	
func solve_part_one():
	# We are going to limit devices to those in paths
	var all_device_keys := devices.keys()
	var relevant_device_keys: Dictionary = {}
	
	var start_device = devices["you"]
	
	if debug:
		print("\nStart Device:\n", start_device)
	
	# Loop through the devices in the start "you" device
	for device in start_device:
		if device != "out" and device != "you":
			relevant_device_keys.set(device, true)
			
		if debug:
			print("\nDEVICE: ", device)
		
	var start_size = relevant_device_keys.size()
	var end_size = 0
	print("START: ", start_size, " END: ", end_size)
	while (start_size != end_size):
		# Loop through all sub_devices
		var loop_device_keys = relevant_device_keys.duplicate().keys()
		start_size = loop_device_keys.size()
		for sub_device in loop_device_keys:
			if sub_device != "out" and sub_device != "you":
				for sub_sub_device in devices[sub_device]:
					print(sub_sub_device)
					if sub_sub_device != "out" and sub_sub_device != "you":
						relevant_device_keys.set(sub_sub_device, true)
				
		end_size = relevant_device_keys.size()
		print("START: ", start_size, " END: ", end_size)
		
	if debug:
		print("\nRelevant Device Keys:\n", relevant_device_keys.keys())
	
	for device_key in devices.keys():
		if not relevant_device_keys.has(device_key):
			devices.erase(device_key)
			
	print("\nFinal Relevant Devices:\n", devices)
	
	pass

func solve_part_two():
	pass
