class_name DSU
var parent: Array[int]
var size: Array[int]
var components: int

func _init(n: int) -> void:
	parent = []
	size = []
	parent.resize(n)
	size.resize(n)
	components = n
	for i in n:
		parent[i] = i
		size[i] = 1

func find(a: int) -> int:
	while parent[a] != a:
		parent[a] = parent[parent[a]] # path compression
		a = parent[a]
	return a

func union(a: int, b: int) -> bool:
	var ra := find(a)
	var rb := find(b)
	if ra == rb:
		return false
	# union by size
	if size[ra] < size[rb]:
		var tmp := ra
		ra = rb
		rb = tmp
	parent[rb] = ra
	size[ra] += size[rb]
	components -= 1
	return true
