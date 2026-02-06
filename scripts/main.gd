extends Node2D

# stores the correct set of connections
var solution = [
	["Part1", "Part2"],
	#["Part2", "Part3"],
	#["Part3", "Part4"],
]

# stores the connections
var part_connections: Array = []

func _ready() -> void:
	# Connect signals from all parts
	#_connect_signals()
	
	#$Part1.connect("connected", _on_parts_connected)
	#$Part1.connect("disconnected", _on_parts_disconnected)
	#$Part2.connect("connected", _on_parts_connected)
	#$Part2.connect("disconnected", _on_parts_disconnected)
	#$Part3.connect("connected", _on_parts_connected)
	#$Part3.connect("disconnected", _on_parts_disconnected)
	#$Part4.connect("connected", _on_parts_connected)
	#$Part4.connect("disconnected", _on_parts_disconnected)
	
	pass

#func _connect_signals() -> void:
	#for child in get_children():
		#if child.has_signal("connected"):
			#child.parts_connected.connect(_on_parts_connected())
			#child.parts_disconnected.connect(_on_parts_disconnected())
			#print(child.name, " has connected signal: ", child.has_signal("connected"))

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
	
