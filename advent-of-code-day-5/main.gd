extends Control

enum Part {
	ONE,
	TWO
}
@export var part: Part = Part.ONE
@export_enum("Use Sample", "Use Input") var data_to_use := "Use Sample"
@export_file("*.txt") var sample_input_file: String
@export_file("*.txt") var input_file: String
@export var debug: bool = false
@onready var progress_bar = $Panel/ProgressBar
@onready var item_list = $Panel/ItemList

var instructions:Array[String] = []
var fresh_rules := []
var ingredients := []

var total_fresh := 0

var worker_thread: Thread
var is_running := false
var cancel_requested := false
var _mutex = Mutex.new()

var progress := 0.0
var total_items := 0

func _ready() -> void:
	var input_file_path = sample_input_file if data_to_use == "Use Sample" else input_file
	instructions = InstructionLoader.load_instructions(input_file_path)
	call_deferred("parse_instructions")

func _process(_delta: float) -> void:
	if not is_running:
		return
		
	if part == Part.TWO:
		_mutex.lock()
		var p := progress
		_mutex.unlock()
		
		progress_bar.value = p * 100.0

func parse_instructions() -> void:
	for line in instructions:
		if line.contains("-"):
			var line_arr = line.split("-")
			var min_val: int = int(line_arr[0])
			var max_val: int = int(line_arr[1])
			fresh_rules.append({ "min": min_val, "max": max_val})
		else:
			ingredients.append(int(line))
			
	if debug:
		print("RULES: ", fresh_rules)
		print("INGREDIENTS: ", ingredients)

func solve_part_1() -> void:
	for ingredient in ingredients:
		if debug:
			print("Ingredient: ", ingredient)
		for rule in fresh_rules:
			if ingredient >= rule.min and ingredient <= rule.max:
				if debug:
					print("Fresh for: ", rule)
				total_fresh += 1
				break
	
	# The reuslt
	print("TOTAL FRESH INGREDIENTS: ", total_fresh)
	
func solve_part_2() -> void:
	if worker_thread != null and worker_thread.is_started():
		push_warning("Thread already running")
		return
	
	progress = 0.0
	total_items = fresh_rules.size()
	cancel_requested = false
	
	worker_thread = Thread.new()
	print("Worker thread created.")
	is_running = true
	var err = worker_thread.start(_thread_process)
	print("Worker thread started.")
	if err != OK:
		push_error("Failed to start thread: %s" % err)
		is_running = false
	
	


func _thread_process() -> void:
	var processed := 0
	var count := fresh_rules.size()
	
	var total_fresh_ingredients := 0
	
	var reduce_ranges := func(rules: Array) -> Array:
		if rules.is_empty():
			return []

		# 1. Make a copy so we don't mutate the original
		var sorted := rules.duplicate()

		# 2. Sort by "min"
		sorted.sort_custom(func(a, b):
			return a["min"] < b["min"]
		)

		# 3. Walk and merge
		var merged: Array = []
		var current: Dictionary = sorted[0].duplicate()

		for i in range(1, sorted.size()):
			var r = sorted[i]
			var cur_min = current["min"]
			var cur_max = current["max"]
			var r_min = r["min"]
			var r_max = r["max"]

			# Overlap or touching? (use +1 if you want adjacency to merge)
			if r_min <= cur_max:
				current["max"] = max(cur_max, r_max)
			else:
				merged.append(current)
				current = r.duplicate()

		merged.append(current)
		return merged

		
	var final_ranges = reduce_ranges.call(fresh_rules)
		
	for range in final_ranges:
		total_fresh_ingredients += (range["max"] - range["min"]) + 1
	
	print("Ranges: ", final_ranges)
	call_deferred("_on_thread_done", total_fresh_ingredients, processed)
	
func _on_thread_done(fresh_ingredient_ids_size: int, processed: int) -> void:
	is_running = false
	
	if worker_thread != null and worker_thread.is_started():
		worker_thread.wait_to_finish()
		worker_thread = null
	
	print("Number of fresh ingredients: ", fresh_ingredient_ids_size)

func _on_button_pressed():
	if part == Part.ONE:
		solve_part_1()
	
	if part == Part.TWO:
		solve_part_2()
