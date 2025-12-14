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

@onready var points_container: Node3D = $PointsContainer
@onready var camera_3d: Camera3D = $Camera3D

@export var view_distance: float = 16.0
@export var view_height: float = 2.0
@export var move_time: float = 0.8
@export var hold_time: float = 0.3
@export var loop_showcase: bool = true

@export var initial_hold_time: float = 2.5       # Time camera holds the “wide shot”
@export var initial_framing_padding: float = 1.5 # Multiplier for how far back to pull camera
@export var orbit_duration: float = 6.0  # seconds to orbit once around the cluster


var _points: Array[Node3D] = []
var _current_index: int = 0
var _running: bool = false

# POINTS / BOXES
@export var point_box_size: float = 3.5  # world units for CSGBox3D size
@export var point_segments := 12
@export var rings := 8
@export var box_material: Material

# ROPES
@export var radius: float = 0.4               # Cylinder thickness
@export var segments: int = 12                 # Smoothness of cylinder
@export var string_material: Material
var cylinders: Array[MeshInstance3D] = []      # Handles to created cylinders


var instructions := []
var grand_total := 0
var points: PackedVector3Array
var distances: Dictionary = {}

func _ready() -> void:
	var input_file_path = sample_input_file if data_to_use == "Use Sample" else input_file
	instructions = InstructionLoader.load_instructions(input_file_path)
	
	if camera_3d == null:
		push_warning("Camera reference not assigned on Main.")
		return
	if points_container == null:
		push_warning("points_container not assigned on Main.")
		return
	
	if debug:
		print(instructions)
	
	if part == Part.ONE:
		call_deferred("solve_part_one")
	if part == Part.TWO:
		call_deferred("solve_part_two")
	
func solve_part_one():
	for line in instructions:
		var xyz = line.split(",")
		var new_point: Vector3 = Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
		
		#var point := CSGBox3D.new()
		#point.size = Vector3.ONE * point_box_size        # make each point bigger
		var point := CSGSphere3D.new()
		point.radius = point_box_size
		point.radial_segments = segments
		point.rings = rings
		point.position = new_point
		point.material = box_material
		points_container.add_child(point)

	points.clear()
	for child in $PointsContainer.get_children():
		if child is Node3D:
			points.append(child.global_position)
	
	var number_of_closest_pairs = 10 if data_to_use == "Use Sample" else 1000
	var closest_pairs = get_top_closest_pairs(number_of_closest_pairs)
	if debug:
		for pair in closest_pairs:
			print("Points ", pair.i, " and ", pair.j, " distance = ", sqrt(pair.d2))
		
	var clusters = get_point_clusters_from_pairs(closest_pairs)
	if debug:
		print("CLUSTERS: ", clusters)
	var product := 1
	clusters.sort_custom(func(a,b): 
		return a.size() > b.size()
		)
	if debug:
		print("SORTED CLUSTERS:", clusters)
	for i in 3:
		product *= clusters[i].size()
	print("TOTAL: ", product)
	
	#draw a line between them
	_build_cluster_connections(clusters)
	
	
	_collect_points()
	if _points.is_empty():
		push_warning("points_container has no Node3D children.")
		return

	if debug:
		_running = true
		_run_showcase()
	else: 
		await _do_initial_framing_shot(true)

func solve_part_two():
	pass

func get_top_closest_pairs(amount: int = 10) -> Array:
	var results: Array = []
	var count := points.size()

	# 1) Generate all unique pairs + distance_squared
	for i in range(count):
		for j in range(i + 1, count):
			var d2 := points[i].distance_squared_to(points[j])
			results.append({
				"i": i,
				"j": j,
				"d2": d2
			})

	# 2) Sort by distance
	results.sort_custom(func(a, b):
		return a["d2"] < b["d2"]
	)

	# 3) Slice out the top N entries
	if results.size() > amount:
		results = results.slice(0, amount)

	return results

func get_point_clusters_from_pairs(pairs: Array) -> Array:
	# Build adjacency: point_index -> Array[int] of neighbors
	var neighbors: Dictionary = {}  # int -> Array[int]

	for pair in pairs:
		var a: int = pair["i"]
		var b: int = pair["j"]

		if not neighbors.has(a):
			neighbors[a] = []
		if not neighbors.has(b):
			neighbors[b] = []

		neighbors[a].append(b)
		neighbors[b].append(a)

	var clusters: Array = []
	var visited: Dictionary = {}  # int -> bool

	# DFS/BFS over the adjacency to find connected components
	for start_point in neighbors.keys():
		if visited.has(start_point):
			continue

		var stack: Array[int] = [start_point]
		var component: Array[int] = []

		while not stack.is_empty():
			var current: int = stack.pop_back()
			if visited.has(current):
				continue

			visited[current] = true
			component.append(current)

			var current_neighbors: Array = neighbors[current]
			for n in current_neighbors:
				if not visited.has(n):
					stack.append(n)

		component.sort()  # optional: keep indices in order
		clusters.append(component)

	return clusters


func _solve_distances():
	# Get the 10/1000 shortest distances
	var arr: Array[Vector3] = []
	arr.resize(points.size())
	for i in arr.size():
		arr[i] = points[i]
		
	arr.sort_custom(_sort_function)
	return PackedVector3Array(arr)
	
func _sort_function(a: Vector3, b: Vector3) -> bool:
	print("A: ", a)
	print("B: ", b)
	var distance = _distance_between_points(a, b)
	distances.set(distance, [a, b])
	return false

func _build_connections():
	# Clean up old cylinders if script reloads
	for cyl in cylinders:
		cyl.queue_free()
	cylinders.clear()

	# Loop through each segment between points
	for i in points.size():
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % points.size()]  # loops back to first

		var cyl := _create_cylinder_between(a, b)
		add_child(cyl)
		cylinders.append(cyl)

func _build_cluster_connections(clusters):
	for cyl in cylinders:
		cyl.queue_free()
	cylinders.clear()
	
	for g in clusters.size():
		for i in clusters[g].size()-1:
			var a: Vector3 = points[clusters[g][i]]
			var b: Vector3 = points[clusters[g][(i + 1) % clusters[g].size()]]
			
			var cyl := _create_cylinder_between(a, b)
			add_child(cyl)
			cylinders.append(cyl)

func _create_cylinder_between(a: Vector3, b: Vector3) -> MeshInstance3D:
	var cyl_instance := MeshInstance3D.new()

	# Mesh setup
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = segments
	mesh.rings = 1
	cyl_instance.mesh = mesh
	cyl_instance.material_override = string_material


	# Midpoint
	var mid := (a + b) * 0.5

	# Direction from A to B
	var dir: Vector3 = (b - a)
	var dir_norm: Vector3 = dir.normalized()

	# Cylinder's default orientation is along +Y
	# Rotate it from UP axis into the direction vector
	var rotation_quat := Quaternion(Vector3.UP, dir_norm)
	var basis := Basis(rotation_quat)

	# Assign transform
	cyl_instance.global_transform = Transform3D(basis, mid)

	return cyl_instance

func _collect_points() -> void:
	_points.clear()

	for child in points_container.get_children():
		if child is Node3D:
			_points.append(child)

func _run_showcase() -> void:
	await _do_initial_framing_shot()
	
	# coroutine loop
	while _running and not _points.is_empty():
		var target: Node3D = _points[_current_index]

		await _move_camera_to_target(target)
		await get_tree().create_timer(hold_time).timeout

		# next target
		_current_index += 1
		if _current_index >= _points.size():
			if loop_showcase:
				_current_index = 0
			else:
				_running = false

# -----------------------------------------------------
# INITIAL WIDE SHOT FOR ALL POINTS
# -----------------------------------------------------

func _do_initial_framing_shot(zoom: bool = false) -> void:
	var positions: Array[Vector3] = []
	for p: Node3D in _points:
		positions.append(p.global_position)

	if positions.is_empty():
		return

	# Build bounding box around all points
	var aabb: AABB = AABB(positions[0], Vector3.ZERO)
	for i: int in range(1, positions.size()):
		aabb = aabb.expand(positions[i])

	var center: Vector3 = aabb.get_center()

	# Compute a radius that roughly covers the bounds
	var half_x: float = aabb.size.x * 0.5
	var half_y: float = aabb.size.y * 0.5
	var half_z: float = aabb.size.z * 0.5
	var bounds_radius: float = max(half_x, max(half_y, half_z))

	# Horizontal FOV → distance needed to see the radius
	var fov_radians: float = deg_to_rad(camera_3d.fov)
	var camera_distance: float = (bounds_radius / tan(fov_radians * 0.5)) * initial_framing_padding

	# --- Step 1: move into an initial orbit position (angle 0) ---

	var start_angle: float = 0.0
	var initial_pos: Vector3 = center \
		+ Vector3(cos(start_angle), 0.0, sin(start_angle)) * camera_distance \
		+ Vector3.UP * view_height

	var initial_dir: Vector3 = (center - initial_pos).normalized()
	var initial_basis: Basis = Basis().looking_at(initial_dir, Vector3.UP)
	var initial_xform: Transform3D = Transform3D(initial_basis, initial_pos)

	var tween: Tween = create_tween()
	tween.tween_property(
		camera_3d,
		"global_transform",
		initial_xform,
		move_time * 1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	# --- Step 2: orbit once around the cluster, with optional zoom ---

	var elapsed: float = 0.0
	var end_angle: float = TAU  # 2 * PI, full circle

	# How close to get at max zoom (0.5 = half the distance)
	var zoom_factor: float = 0.5

	while elapsed < orbit_duration:
		var t: float = elapsed / orbit_duration
		var angle: float = lerp(start_angle, end_angle, t)

		# Base distance
		var distance: float = camera_distance

		if zoom:
			# Map t [0,1] → zoom_t [0,2]
			var zoom_t: float = t * 2.0

			if zoom_t <= 1.0:
				# First half of orbit: zoom in
				# 0 → 1 : distance goes from camera_distance → camera_distance * zoom_factor
				distance = lerp(camera_distance, camera_distance * zoom_factor, zoom_t)
			else:
				# Second half of orbit: zoom back out
				# 1 → 2 : distance goes from camera_distance * zoom_factor → camera_distance
				zoom_t -= 1.0
				distance = lerp(camera_distance * zoom_factor, camera_distance, zoom_t)

		var pos: Vector3 = center \
			+ Vector3(cos(angle), 0.0, sin(angle)) * distance \
			+ Vector3.UP * view_height

		var dir: Vector3 = (center - pos).normalized()
		var basis: Basis = Basis().looking_at(dir, Vector3.UP)
		camera_3d.global_transform = Transform3D(basis, pos)

		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# Optional: small pause after orbit before starting point-by-point
	if initial_hold_time > 0.0:
		await get_tree().create_timer(initial_hold_time).timeout




# -----------------------------------------------------
# NORMAL SINGLE-TARGET CAMERA MOVEMENT
# -----------------------------------------------------

func _move_camera_to_target(target: Node3D) -> void:
	var target_pos := target.global_position

	var forward := -target.global_transform.basis.z
	if forward.length() == 0.0:
		forward = -Vector3.FORWARD
	forward = forward.normalized()

	var cam_pos := target_pos - forward * view_distance + Vector3.UP * view_height

	var dir := (target_pos - cam_pos).normalized()
	var basis := Basis().looking_at(dir, Vector3.UP)
	var desired_xform := Transform3D(basis, cam_pos)

	var tween := create_tween()
	tween.tween_property(
		camera_3d,
		"global_transform",
		desired_xform,
		move_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished


func _distance_between_points(p: Vector3, q: Vector3) -> float:
	var x_diff := p.x - q.x
	var y_diff := p.y - q.y
	var z_diff := p.z - q.z
	var under_square_root = pow(x_diff, 2.0) + pow(y_diff, 2.0) + pow(z_diff, 2.0)
	var distance = sqrt(under_square_root)
	return distance
