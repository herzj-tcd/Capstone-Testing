extends Node2D

# stores the correct set of connections
var solution = [
	["Part1", "Part2"],
	["Part2", "Part3"],
	["Part3", "Part4"],
]

# stores the connections
var part_connections: Array = []

func _ready() -> void:
	# Connect signals from all parts
	for child in get_children():
		if child.has_signal("parts_connected"):
			child.connect("parts_connected", _on_parts_connected)
			child.connect("parts_disconnected", _on_parts_disconnected)

# keeps the order of part connections consistent
func _make_pair(a: Node, b: Node) -> Array:
	if a.name > b.name:
		return [a.name, b.name]
	else:
		return [b.name, a.name]

func _on_parts_connected(part_a: Node, part_b: Node) -> void:
	var pair = _make_pair(part_a, part_b)
	if pair not in part_connections:
		part_connections.append(pair)
	_check_assembly()

func _on_parts_disconnected(part_a: Node, part_b: Node) -> void:
	var pair = _make_pair(part_a, part_b)
	part_connections.erase(pair)
	
# checks to see if the solution has been met
func _check_assembly() -> void:
	
	# makes sure both lists are sorted
	var sorted_solution = solution.duplicate(true)
	sorted_solution.sort()
	var sorted_actual = part_connections.duplicate(true)
	sorted_actual.sort()
	
	if sorted_actual == sorted_solution:
		print("Assembly complete")
	
