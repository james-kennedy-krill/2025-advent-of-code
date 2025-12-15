extends Node2D

enum Part {
	ONE,
	TWO
}
@export var part: Part = Part.ONE
@export var red_tile_char: String = "#"
@export var white_tile_char: String = "."
@export_enum("Use Sample", "Use Input") var data_to_use := "Use Sample"
@export_file("*.txt") var sample_input_file: String
@export_file("*.txt") var input_file: String

@onready var background: TileMapLayer = $Background
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var cam: Camera2D = $Camera2D

var instructions := []
var red_tile_coords: Array[Vector2i]
var _red_tile_x_max := 0
var _red_tile_y_max := 0

var _tile_rows := 0
var _tile_cols := 0

var _shape_min_cell: Vector2i
var _shape_max_cell: Vector2i


@export var tileset_souce: int = 1

var RED_TILE = Vector2i(0, 0)
var WHITE_TILE = Vector2i(0, 1)
var GREEN_TILE = Vector2i(0, 2)

var _xs: PackedInt32Array
var _ys: PackedInt32Array
var _x_to_i: Dictionary
var _y_to_i: Dictionary


func _ready() -> void:
	var input_file_path: String = sample_input_file if data_to_use == "Use Sample" else input_file
	instructions = InstructionLoader.load_instructions(input_file_path)

	var raw_points: Array[Vector2i] = []
	raw_points.resize(0)

	# collect raw points + unique xs/ys
	var x_set: Dictionary = {}
	var y_set: Dictionary = {}

	for line: String in instructions:
		var coords_arr: PackedStringArray = line.split(",")
		var x: int = int(coords_arr[0])
		var y: int = int(coords_arr[1])
		raw_points.append(Vector2i(x, y))
		x_set[x] = true
		y_set[y] = true

	# build sorted unique lists
	var xs_arr: Array[int] = []
	for k in x_set.keys():
		xs_arr.append(int(k))
	xs_arr.sort()

	var ys_arr: Array[int] = []
	for k in y_set.keys():
		ys_arr.append(int(k))
	ys_arr.sort()

	# store for area lookup
	_xs = PackedInt32Array(xs_arr)
	_ys = PackedInt32Array(ys_arr)

	# build maps: original -> compressed (even coords)
	_x_to_i = {}
	for i: int in range(_xs.size()):
		_x_to_i[_xs[i]] = i * 2

	_y_to_i = {}
	for i: int in range(_ys.size()):
		_y_to_i[_ys[i]] = i * 2

	# compress points
	red_tile_coords.clear()
	for p: Vector2i in raw_points:
		var cx: int = int(_x_to_i[p.x])
		var cy: int = int(_y_to_i[p.y])
		red_tile_coords.append(Vector2i(cx, cy))

	# grid size in compressed space (+ a little border)
	_tile_cols = (_xs.size() * 2) + 3
	_tile_rows = (_ys.size() * 2) + 3

	build_movie_theater_floor()

	if part == Part.ONE:
		call_deferred("run_part_1")
	elif part == Part.TWO:
		call_deferred("run_part_2")

	tile_map_layer.update_internals()
	zoom_camera()


func build_movie_theater_floor() -> void:
	# place white tiles on background
	#for x in _tile_cols:
		#for y in _tile_rows:
			#background.set_cell(Vector2i(x, y), tileset_souce, WHITE_TILE) 
	
	# place red tiles on TileMapLayer
	for red_tile in red_tile_coords:
		tile_map_layer.set_cell(red_tile, tileset_souce, RED_TILE)
	
func zoom_camera() -> void:
	if _tile_rows <= 0 or _tile_cols <= 0:
		return

	var width = _tile_cols * 16
	var height = _tile_rows * 16

	# 3) Compute zoom so the whole rect fits the viewport
	var viewport_size: Vector2 = cam.get_viewport_rect().size

	# Smaller zoom = zoom OUT → see more.
	# We want the largest zoom that still fits both width and height.
	var zoom_x: float = viewport_size.x / width
	var zoom_y: float = viewport_size.y / height
	var z: float = min(zoom_x, zoom_y)

	# Optional: give yourself a little border so tiles aren't right on the edge
	z *= 0.95

	cam.zoom = Vector2(z, z)
	
func run_part_1() -> void:
	var result := find_largest_rect_pair(red_tile_coords)
	print(result)
	fill_rect_with_pattern(
		$Background,
		result.min,
		result.max,
		tileset_souce,                # source id in TileSet
		RED_TILE    # atlas coords
	)

	
func run_part_2() -> void:
	print(red_tile_coords)
	build_and_paint_shape(red_tile_coords)



func find_largest_rect_pair(points: Array[Vector2i]) -> Dictionary:
	# Returns:
	# {
	#   "a": Vector2i,      # point from the input
	#   "b": Vector2i,      # point from the input (opposite corner)
	#   "area": int,        # abs(dx) * abs(dy)
	#   "min": Vector2i,    # normalized min corner (may be a or b)
	#   "max": Vector2i     # normalized max corner (may be a or b)
	# }
	if points.size() < 2:
		return { "a": Vector2i.ZERO, "b": Vector2i.ZERO, "area": 0, "min": Vector2i.ZERO, "max": Vector2i.ZERO }

	var best_a: Vector2i = points[0]
	var best_b: Vector2i = points[1]
	var best_area: int = -1

	for i in range(points.size() - 1):
		var a := points[i]
		for j in range(i + 1, points.size()):
			var b := points[j]

			var dx: int = abs(a.x - b.x)
			var dy: int = abs(a.y - b.y)
			var area: int = (dx+1) * (dy+1)

			# optional: ignore degenerate rectangles (line/point)
			if area == 0:
				continue

			if area > best_area:
				best_area = area
				best_a = a
				best_b = b

	var min_corner := Vector2i(min(best_a.x, best_b.x), min(best_a.y, best_b.y))
	var max_corner := Vector2i(max(best_a.x, best_b.x), max(best_a.y, best_b.y))

	return {
		"a": best_a,
		"b": best_b,
		"area": max(best_area, 0),
		"min": min_corner,
		"max": max_corner
	}

func fill_rect_with_pattern(
	layer: TileMapLayer,
	corner_a: Vector2i,
	corner_b: Vector2i,
	source_id: int,
	atlas_coords: Vector2i,
	alternative_tile: int = 0
) -> void:
	var min_x :int = min(corner_a.x, corner_b.x)
	var max_x :int = max(corner_a.x, corner_b.x)
	var min_y :int = min(corner_a.y, corner_b.y)
	var max_y :int = max(corner_a.y, corner_b.y)

	var w := (max_x - min_x) + 1
	var h := (max_y - min_y) + 1

	var pattern := TileMapPattern.new()
	pattern.set_size(Vector2i(w, h)) # :contentReference[oaicite:3]{index=3}

	for y in range(h):
		for x in range(w):
			pattern.set_cell(Vector2i(x, y), source_id, atlas_coords, alternative_tile) # :contentReference[oaicite:4]{index=4}

	layer.set_pattern(Vector2i(min_x, min_y), pattern) # :contentReference[oaicite:5]{index=5}


# Part 2 functions
# --- Helpers ---
const DIR_E := Vector2i(1, 0)
const DIR_W := Vector2i(-1, 0)
const DIR_S := Vector2i(0, 1)
const DIR_N := Vector2i(0, -1)

func _right_of(d: Vector2i) -> Vector2i:
	if d == DIR_E: return DIR_S
	if d == DIR_S: return DIR_W
	if d == DIR_W: return DIR_N
	return DIR_E # DIR_N -> DIR_E

func _left_of(d: Vector2i) -> Vector2i:
	return -_right_of(-d)

func _remove_collinear(loop: Array[Vector2i]) -> Array[Vector2i]:
	if loop.size() < 3:
		return loop

	var out: Array[Vector2i] = []
	for i in range(loop.size()):
		var prev := loop[(i - 1 + loop.size()) % loop.size()]
		var cur := loop[i]
		var nxt := loop[(i + 1) % loop.size()]

		var d0 := cur - prev
		var d1 := nxt - cur

		# If cur lies on a straight vertical or horizontal run, drop it.
		if (d0.x == 0 and d1.x == 0) or (d0.y == 0 and d1.y == 0):
			continue

		out.append(cur)

	return out

# Returns adjacency dictionary:
# adj[p] = { DIR_E: neighbor, DIR_W: neighbor, DIR_S: neighbor, DIR_N: neighbor } (some may be missing)
func build_cardinal_adjacency(points: Array[Vector2i]) -> Dictionary:
	var by_x: Dictionary = {} # int -> Array[Vector2i]
	var by_y: Dictionary = {} # int -> Array[Vector2i]

	for p in points:
		if not by_x.has(p.x): by_x[p.x] = []
		if not by_y.has(p.y): by_y[p.y] = []
		(by_x[p.x] as Array).append(p)
		(by_y[p.y] as Array).append(p)

	# sort buckets
	for x in by_x.keys():
		var arr: Array = by_x[x]
		arr.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y < b.y
		)

	for y in by_y.keys():
		var arr: Array = by_y[y]
		arr.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.x < b.x
		)

	var adj: Dictionary = {}

	# vertical nearest neighbors
	for x in by_x.keys():
		var arr: Array = by_x[x]
		for i in range(arr.size()):
			var p: Vector2i = arr[i]
			if not adj.has(p): adj[p] = {}
			var d: Dictionary = adj[p]
			if i > 0:
				d[DIR_N] = arr[i - 1]
			if i < arr.size() - 1:
				d[DIR_S] = arr[i + 1]

	# horizontal nearest neighbors
	for y in by_y.keys():
		var arr: Array = by_y[y]
		for i in range(arr.size()):
			var p: Vector2i = arr[i]
			if not adj.has(p): adj[p] = {}
			var d: Dictionary = adj[p]
			if i > 0:
				d[DIR_W] = arr[i - 1]
			if i < arr.size() - 1:
				d[DIR_E] = arr[i + 1]

	return adj

func trace_outer_loop(points: Array[Vector2i]) -> Array[Vector2i]:
	if points.size() < 3:
		return points.duplicate()

	var adj: Dictionary = build_cardinal_adjacency(points)

	# start: lowest y, then lowest x
	var start: Vector2i = points[0]
	for p: Vector2i in points:
		if p.y < start.y or (p.y == start.y and p.x < start.x):
			start = p

	if not adj.has(start):
		return []

	# IMPORTANT: start heading east along the top edge
	var dir: Vector2i = DIR_E
	var cur: Vector2i = start
	var loop: Array[Vector2i] = []

	var safety: int = 0
	var safety_max: int = max(2000, points.size() * 10)

	while true:
		loop.append(cur)

		var neighs: Dictionary = adj[cur]

		# FIX: go straight first so we stay on the outer boundary
		var candidates: Array[Vector2i] = [dir, _right_of(dir), _left_of(dir), -dir]

		var moved: bool = false
		for nd: Vector2i in candidates:
			if neighs.has(nd):
				cur = neighs[nd]
				dir = nd
				moved = true
				break

		if not moved:
			return []

		if cur == start and loop.size() > 2:
			break

		safety += 1
		if safety > safety_max:
			return []

	return _remove_collinear(loop)


const EPS := 0.000001

func _dist2(a: Vector2i, b: Vector2i) -> int:
	var dx := a.x - b.x
	var dy := a.y - b.y
	return dx * dx + dy * dy

func _angle_from_dir(dir: Vector2, to: Vector2) -> float:
	# Returns signed angle from dir to to in [-PI, PI]
	return atan2(dir.cross(to), dir.dot(to))

func _orient(a: Vector2i, b: Vector2i, c: Vector2i) -> int:
	# cross((b-a),(c-a))
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

func _on_segment(a: Vector2i, b: Vector2i, p: Vector2i) -> bool:
	return min(a.x, b.x) <= p.x and p.x <= max(a.x, b.x) and \
		   min(a.y, b.y) <= p.y and p.y <= max(a.y, b.y)

func _segments_intersect(a: Vector2i, b: Vector2i, c: Vector2i, d: Vector2i) -> bool:
	# Proper segment intersection including collinear overlaps
	var o1 := _orient(a, b, c)
	var o2 := _orient(a, b, d)
	var o3 := _orient(c, d, a)
	var o4 := _orient(c, d, b)

	if o1 == 0 and _on_segment(a, b, c): return true
	if o2 == 0 and _on_segment(a, b, d): return true
	if o3 == 0 and _on_segment(c, d, a): return true
	if o4 == 0 and _on_segment(c, d, b): return true

	return (o1 > 0) != (o2 > 0) and (o3 > 0) != (o4 > 0)

func _edge_would_intersect(hull: Array[Vector2i], new_a: Vector2i, new_b: Vector2i) -> bool:
	# Check against all existing edges except adjacent ones.
	# hull edges are (hull[i-1] -> hull[i]) for i >= 1
	var n := hull.size()
	if n < 2:
		return false

	for i in range(1, n):
		var e0 := hull[i - 1]
		var e1 := hull[i]

		# skip checking against the edge that shares new_a (the last edge)
		if e0 == new_a or e1 == new_a:
			continue
		# if closing, allow touching at endpoints
		if e0 == new_b or e1 == new_b:
			continue

		if _segments_intersect(new_a, new_b, e0, e1):
			return true

	return false

func _unique_points(points: Array[Vector2i]) -> Array[Vector2i]:
	var seen := {}
	var out: Array[Vector2i] = []
	for p in points:
		if not seen.has(p):
			seen[p] = true
			out.append(p)
	return out

func concave_hull(points_in: Array[Vector2i], k_start: int = 8, k_max: int = 40) -> Array[Vector2i]:
	var points := _unique_points(points_in)
	if points.size() < 3:
		return points

	# Start: lowest y, then lowest x
	var start := points[0]
	for p in points:
		if p.y < start.y or (p.y == start.y and p.x < start.x):
			start = p

	# We'll retry with increasing k until it works.
	for k in range(k_start, k_max + 1):
		var hull: Array[Vector2i] = []
		hull.append(start)

		var current := start
		var prev_dir := Vector2(1, 0) # arbitrary "east"

		var used := {}
		used[start] = true

		var safety := 0
		var safety_max := points.size() * 5

		while safety < safety_max:
			safety += 1

			# Build k nearest candidates (excluding current; allow start only for closing)
			var candidates: Array[Vector2i] = []
			candidates = points.duplicate()
			candidates.erase(current)

			candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				return _dist2(current, a) < _dist2(current, b)
			)

			if candidates.size() > k:
				candidates.resize(k)

			# Sort candidates by smallest "right turn" / smallest absolute turn from prev_dir
			# (This tends to wrap around the outside, but still needs intersection checks.)
			candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				var va := Vector2(a.x - current.x, a.y - current.y).normalized()
				var vb := Vector2(b.x - current.x, b.y - current.y).normalized()
				var aa := _angle_from_dir(prev_dir, va)
				var ab := _angle_from_dir(prev_dir, vb)
				# Prefer turning clockwise first (more negative), then by magnitude
				# If you get the loop going the "wrong way", swap these comparisons.
				if abs(aa - ab) < EPS:
					return _dist2(current, a) < _dist2(current, b)
				return aa < ab
			)

			var picked: Vector2i = Vector2i.ZERO
			var found := false

			for nxt in candidates:
				# Don’t reuse points too early (except we can close to start)
				if used.has(nxt) and nxt != start:
					continue

				# Avoid self-intersection
				if _edge_would_intersect(hull, current, nxt):
					continue

				# If nxt == start, only close if we have enough points to form a loop
				if nxt == start and hull.size() < 3:
					continue

				picked = nxt
				found = true
				break

			if not found:
				# fail with this k
				hull.clear()
				break

			# Close loop
			if picked == start:
				return hull # ordered perimeter (not repeating start at end)

			hull.append(picked)
			used[picked] = true

			prev_dir = Vector2(picked.x - current.x, picked.y - current.y).normalized()
			current = picked

	# If we got here: failed all k values
	return []

func _rasterize_orthogonal_edge(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	if a.x == b.x:
		var x: int = a.x
		var y0: int = min(a.y, b.y)
		var y1: int = max(a.y, b.y)
		for y: int in range(y0, y1 + 1):
			out.append(Vector2i(x, y))
		return out

	if a.y == b.y:
		var y: int = a.y
		var x0: int = min(a.x, b.x)
		var x1: int = max(a.x, b.x)
		for x: int in range(x0, x1 + 1):
			out.append(Vector2i(x, y))
		return out

	# Not allowed in an orthogonal perimeter
	return []



func _bresenham(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	var x0 := a.x
	var y0 := a.y
	var x1 := b.x
	var y1 := b.y

	var dx :int = abs(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy :int = -abs(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy

	while true:
		out.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

	return out

func order_from_input_path(points_in: Array[Vector2i]) -> Array[Vector2i]:
	if points_in.size() < 3:
		return points_in.duplicate()

	# 1) remove consecutive duplicates
	var pts: Array[Vector2i] = []
	for p: Vector2i in points_in:
		if pts.is_empty() or pts[pts.size() - 1] != p:
			pts.append(p)

	# 2) if last == first, drop last
	if pts.size() > 1 and pts[0] == pts[pts.size() - 1]:
		pts.remove_at(pts.size() - 1)

	# 3) remove collinear
	return _remove_collinear(pts)


func build_and_paint_shape(points: Array[Vector2i]) -> void:
	if points.size() < 3:
		push_error("Need at least 3 points.")
		return

	# Prefer grid-walk perimeter tracing for orthogonal polygons
	#var ordered: Array[Vector2i] = trace_outer_loop(points)
	var ordered: Array[Vector2i] = order_from_input_path(points)
	if ordered.is_empty():
		# Fallback only if needed
		ordered = concave_hull(points, 8, 60)

	if ordered.is_empty():
		push_error("Could not build perimeter ordering.")
		return

	print("ORDERED:", ordered)
	paint_polygon_perimeter_and_fill(
		tile_map_layer,
		ordered,
		tileset_souce, RED_TILE,    # corners
		tileset_souce, GREEN_TILE,  # perimeter
		tileset_souce, GREEN_TILE,  # fill
		0,
		2
	)

	tile_map_layer.update_internals()



func _in_bb(p: Vector2i, bb_min: Vector2i, bb_max: Vector2i) -> bool:
	return p.x >= bb_min.x and p.x <= bb_max.x and p.y >= bb_min.y and p.y <= bb_max.y


func paint_polygon_perimeter_and_fill(
	layer: TileMapLayer,
	ordered_vertices: Array[Vector2i],

	# corner tile
	corner_source_id: int,
	corner_atlas: Vector2i,

	# perimeter tile (between vertices)
	perimeter_source_id: int,
	perimeter_atlas: Vector2i,

	# fill tile (inside)
	fill_source_id: int,
	fill_atlas: Vector2i,

	alternative_tile: int = 0,
	padding: int = 2
) -> void:
	if ordered_vertices.size() < 3:
		return

	# --- Sets ---
	var corners := {}   # Set[Vector2i]
	var boundary := {}  # Set[Vector2i]

	for v in ordered_vertices:
		corners[v] = true

	# --- Rasterize edges into boundary set + compute bounds ---
	var min_x := ordered_vertices[0].x
	var max_x := ordered_vertices[0].x
	var min_y := ordered_vertices[0].y
	var max_y := ordered_vertices[0].y

	for i in range(ordered_vertices.size()):
		var a := ordered_vertices[i]
		var b := ordered_vertices[(i + 1) % ordered_vertices.size()]

		#for c in _bresenham(a, b):
		var edge_cells: Array[Vector2i] = _rasterize_orthogonal_edge(a, b)
		if edge_cells.is_empty():
			push_error("Bad perimeter edge (non-orthogonal): %s -> %s" % [str(a), str(b)])
			return
		for c: Vector2i in edge_cells:
			boundary[c] = true
			# bounds update...

			boundary[c] = true
			min_x = min(min_x, c.x)
			max_x = max(max_x, c.x)
			min_y = min(min_y, c.y)
			max_y = max(max_y, c.y)

	# --- 1) Paint perimeter everywhere EXCEPT corners ---
	for cell in boundary.keys():
		if corners.has(cell):
			continue
		layer.set_cell(cell, perimeter_source_id, perimeter_atlas, alternative_tile)

	# --- 2) Paint corners (overrides perimeter if overlap) ---
	for v in corners.keys():
		layer.set_cell(v, corner_source_id, corner_atlas, alternative_tile)

	# --- 3) Flood fill outside, constrained to a padded bounding box ---
	var bb_min := Vector2i(min_x - padding, min_y - padding)
	var bb_max := Vector2i(max_x + padding, max_y + padding)

	var outside := {} # Set[Vector2i]
	var q: Array[Vector2i] = []
	var head := 0

	var start := bb_min
	q.append(start)
	outside[start] = true

	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	while head < q.size():
		var cur := q[head]
		head += 1

		for d in dirs:
			var nxt :Vector2i = cur + d
			if not _in_bb(nxt, bb_min, bb_max):
				continue
			if outside.has(nxt):
				continue
			if boundary.has(nxt):
				continue # treat boundary as a wall
			outside[nxt] = true
			q.append(nxt)

	# --- 4) Fill anything inside bounds that's not outside and not boundary ---
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var cell := Vector2i(x, y)
			if boundary.has(cell):
				continue
			if outside.has(cell):
				continue
			layer.set_cell(cell, fill_source_id, fill_atlas, alternative_tile)
			
	# 5) get results
	_shape_min_cell = Vector2i(min_x, min_y)
	_shape_max_cell = Vector2i(max_x, max_y)
	
	var result := find_largest_rect_from_red_corners(
		tile_map_layer,
		_shape_min_cell,
		_shape_max_cell,
		tileset_souce,
		RED_TILE,
		GREEN_TILE,
		GREEN_TILE
	)
	print(result)



func _is_allowed_tile(
	layer: TileMapLayer,
	cell: Vector2i,
	source_id: int,
	allowed_atlas: Array[Vector2i]
) -> bool:
	if layer.get_cell_source_id(cell) != source_id:
		return false

	var ac := layer.get_cell_atlas_coords(cell)
	for a in allowed_atlas:
		if ac == a:
			return true
	return false




func _is_red(layer: TileMapLayer, cell: Vector2i, source_id: int, red_atlas: Vector2i) -> bool:
	return layer.get_cell_source_id(cell) == source_id and layer.get_cell_atlas_coords(cell) == red_atlas



func _prefix_sum_2d(blocked: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	# blocked[y][x] is 1 if blocked else 0
	var h := blocked.size()
	var w := blocked[0].size()

	var ps: Array[PackedInt32Array] = []
	ps.resize(h + 1)
	for y in range(h + 1):
		ps[y] = PackedInt32Array()
		ps[y].resize(w + 1)

	for y in range(1, h + 1):
		var row_sum := 0
		for x in range(1, w + 1):
			row_sum += blocked[y - 1][x - 1]
			ps[y][x] = ps[y - 1][x] + row_sum
	return ps


func _rect_sum(ps: Array[PackedInt32Array], x0: int, y0: int, x1: int, y1: int) -> int:
	# inclusive coords in grid space
	var ax := x0
	var ay := y0
	var bx := x1 + 1
	var by := y1 + 1
	return ps[by][bx] - ps[ay][bx] - ps[by][ax] + ps[ay][ax]


func find_largest_rect_from_red_corners(
	layer: TileMapLayer,
	min_cell: Vector2i,
	max_cell: Vector2i,
	source_id: int,
	red_atlas: Vector2i,
	perimeter_atlas: Vector2i,
	fill_atlas: Vector2i
) -> Dictionary:
	# Collect red "vertex" points inside bounds
	var red_points: Array[Vector2i] = []
	for y: int in range(min_cell.y, max_cell.y + 1):
		for x: int in range(min_cell.x, max_cell.x + 1):
			var c: Vector2i = Vector2i(x, y)
			if _is_red(layer, c, source_id, red_atlas):
				red_points.append(c)

	if red_points.size() < 2:
		return {"area": 0}

	# Build blocked grid (1 if NOT allowed tile, 0 if allowed)
	var w: int = (max_cell.x - min_cell.x) + 1
	var h: int = (max_cell.y - min_cell.y) + 1

	var allowed: Array[Vector2i] = []
	allowed.append(red_atlas)
	allowed.append(perimeter_atlas)
	allowed.append(fill_atlas)

	var blocked: Array[PackedInt32Array] = []
	blocked.resize(h)

	for gy: int in range(h):
		var row: PackedInt32Array = PackedInt32Array()
		row.resize(w)

		var cell_y: int = min_cell.y + gy
		for gx: int in range(w):
			var cell_x: int = min_cell.x + gx
			var cell: Vector2i = Vector2i(cell_x, cell_y)

			var ok: bool = _is_allowed_tile(layer, cell, source_id, allowed)
			row[gx] = 0 if ok else 1

		blocked[gy] = row

	var ps: Array[PackedInt32Array] = _prefix_sum_2d(blocked)

	# Best result
	var best_a: Vector2i = red_points[0]
	var best_b: Vector2i = red_points[1]
	var best_area: int = 0

	# Check all pairs of red corners
	for i: int in range(red_points.size() - 1):
		var a: Vector2i = red_points[i]
		for j: int in range(i + 1, red_points.size()):
			var b: Vector2i = red_points[j]

			# Inclusive TILE bounds in compressed grid coords
			var vx0: int = min(a.x, b.x)
			var vx1: int = max(a.x, b.x)
			var vy0: int = min(a.y, b.y)
			var vy1: int = max(a.y, b.y)

			# Must have non-zero geometric area in original units (dx * dy)
			# (Corners are on even coords in compressed space)
			if (vx0 % 2) != 0 or (vx1 % 2) != 0 or (vy0 % 2) != 0 or (vy1 % 2) != 0:
				continue

			var ix0: int = vx0 / 2
			var ix1: int = vx1 / 2
			var iy0: int = vy0 / 2
			var iy1: int = vy1 / 2

			if ix0 < 0 or ix1 >= _xs.size() or iy0 < 0 or iy1 >= _ys.size():
				continue

			var dx: int = abs(_xs[ix1] - _xs[ix0])
			var dy: int = abs(_ys[iy1] - _ys[iy0])

			# IMPORTANT: area is "number of tiles in the rectangle", inclusive of both edges
			var width_tiles: int = dx + 1
			var height_tiles: int = dy + 1
			var area: int = width_tiles * height_tiles

			# reject degenerate rectangles (line / point)
			if width_tiles <= 1 or height_tiles <= 1:
				continue


			# Convert inclusive tile bounds to prefix-sum indices
			var x0: int = vx0 - min_cell.x
			var x1: int = vx1 - min_cell.x
			var y0: int = vy0 - min_cell.y
			var y1: int = vy1 - min_cell.y

			if x0 < 0 or y0 < 0 or x1 >= w or y1 >= h:
				continue

			# Reject if any non-allowed tile exists in the inclusive tile rectangle
			var blocked_count: int = _rect_sum(ps, x0, y0, x1, y1)
			if blocked_count != 0:
				continue

			if area > best_area:
				best_area = area
				best_a = a
				best_b = b

	if best_area == 0:
		return {"area": 0}

	var out_min: Vector2i = Vector2i(min(best_a.x, best_b.x), min(best_a.y, best_b.y))
	var out_max: Vector2i = Vector2i(max(best_a.x, best_b.x), max(best_a.y, best_b.y))

	return {
		"a": best_a,
		"b": best_b,
		"min": out_min,
		"max": out_max,
		"area": best_area
	}
