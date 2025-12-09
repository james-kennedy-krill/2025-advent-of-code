extends RefCounted
class_name InstructionLoader

static func load_instructions(path: String) -> Array[String]:
	var results: Array[String] = []

	if not FileAccess.file_exists(path):
		push_error("InstructionLoader.load_instructions: File does not exist → %s" % path)
		return results

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("InstructionLoader.load_instructions: Could not open file → %s" % path)
		return results

	while not file.eof_reached():
		var line := file.get_line()
		if line != "":
			results.append(line)

	return results
