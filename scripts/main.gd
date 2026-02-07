extends Node2D

# =============================================================================
# MAIN.GD - Assembly Checker
# =============================================================================
# This script manages the assembly puzzle system. It tracks which parts are
# connected to each other and checks if the player has assembled them correctly
# according to a predefined solution.
#
# How it works:
# 1. Each Part node emits signals when it connects/disconnects from another part
# 2. This script listens to those signals and maintains a list of current connections
# 3. After each connection, it checks if the current state matches the solution
# =============================================================================


# -----------------------------------------------------------------------------
# SOLUTION DEFINITION
# -----------------------------------------------------------------------------
# The solution is an array of pairs, where each pair represents two parts that
# must be connected for the assembly to be correct.
#
# Format: ["PartName1", "PartName2"]
# - Names must match the node names in the scene tree exactly
# - Order within a pair doesn't matter (handled by _make_pair)
# - Add or remove pairs to change what constitutes a "correct" assembly
# -----------------------------------------------------------------------------
var solution = [
	["Part1", "Part2"],
	#["Part2", "Part3"],  # Uncomment to require this connection too
	#["Part3", "Part4"],  # Uncomment to require this connection too
]


# -----------------------------------------------------------------------------
# CONNECTION TRACKING
# -----------------------------------------------------------------------------
# This array stores the current state of all connections the player has made.
# Each element is a pair [PartA, PartB] in alphabetical order.
#
# Example: If Part1 is connected to Part2, and Part3 is connected to Part4:
# part_connections = [["Part1", "Part2"], ["Part3", "Part4"]]
# -----------------------------------------------------------------------------
var part_connections: Array = []


# =============================================================================
# INITIALIZATION
# =============================================================================
func _ready() -> void:
	# Dynamically connect signals from all child parts
	# This approach is better than manually connecting each part because:
	# - It automatically works with any number of parts
	# - You don't need to update this code when adding new parts
	# - It keeps signal management in one place
	for child in get_children():
		# Check if this child has the parts_connected signal (i.e., is a Part)
		if child.has_signal("parts_connected"):
			# Connect both signals to our handler functions
			# When the part emits "parts_connected", call "_on_parts_connected"
			child.parts_connected.connect(_on_parts_connected)
			child.parts_disconnected.connect(_on_parts_disconnected)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# _make_pair(a, b) -> Array
# -----------------------------------------------------------------------------
# Creates a standardized pair from two part nodes.
#
# Why this is needed:
# When Part1 connects to Part2, we might receive the signal as (Part1, Part2)
# or (Part2, Part1) depending on which part was dragged. To compare connections
# properly, we need a consistent order.
#
# This function always returns names in alphabetical order:
# - _make_pair(Part2, Part1) -> ["Part1", "Part2"]
# - _make_pair(Part1, Part2) -> ["Part1", "Part2"]
#
# IMPORTANT: We convert node.name to String because:
# - In Godot 4, node.name returns a StringName type
# - Our solution array contains String types
# - StringName and String don't compare as equal, even with identical text
# - Converting ensures both arrays use the same type for comparison
# -----------------------------------------------------------------------------
func _make_pair(a: Node, b: Node) -> Array:
	# Convert StringName to String to match the solution array's type
	var name_a := String(a.name)
	var name_b := String(b.name)

	# Return in alphabetical order for consistency
	if name_a < name_b:
		return [name_a, name_b]
	else:
		return [name_b, name_a]


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

# -----------------------------------------------------------------------------
# _on_parts_connected(part_a, part_b)
# -----------------------------------------------------------------------------
# Called when any part emits the "parts_connected" signal.
# Adds the connection to our tracking array and checks if assembly is complete.
#
# Parameters:
# - part_a: The part that initiated the connection (the one being dragged)
# - part_b: The part that was connected to (the stationary one)
# -----------------------------------------------------------------------------
func _on_parts_connected(part_a: Node, part_b: Node) -> void:
	#print("Main received signal: ", part_a.name, " -> ", part_b.name)  # DEBUG

	# Create a standardized pair for this connection
	var pair = _make_pair(part_a, part_b)

	# Only add if not already tracked (prevents duplicates)
	if pair not in part_connections:
		part_connections.append(pair)

	# Check if the puzzle is now solved
	_check_assembly()


# -----------------------------------------------------------------------------
# _on_parts_disconnected(part_a, part_b)
# -----------------------------------------------------------------------------
# Called when any part emits the "parts_disconnected" signal.
# Removes the connection from our tracking array.
#
# Parameters:
# - part_a: The part that broke the connection (the one being dragged away)
# - part_b: The part it was previously connected to
# -----------------------------------------------------------------------------
func _on_parts_disconnected(part_a: Node, part_b: Node) -> void:
	# Create the same standardized pair format
	var pair = _make_pair(part_a, part_b)

	# Remove this connection from tracking
	# erase() safely does nothing if the pair doesn't exist
	part_connections.erase(pair)


# =============================================================================
# ASSEMBLY VERIFICATION
# =============================================================================

# -----------------------------------------------------------------------------
# _check_assembly()
# -----------------------------------------------------------------------------
# Compares the current connections against the solution to determine if the
# player has correctly assembled all parts.
#
# How the comparison works:
# 1. Both arrays are duplicated (to avoid modifying originals)
# 2. Both are sorted (so order doesn't matter)
# 3. Direct comparison checks if they're identical
#
# Example:
# - solution = [["Part1", "Part2"], ["Part2", "Part3"]]
# - part_connections = [["Part2", "Part3"], ["Part1", "Part2"]]
# - After sorting both: [["Part1", "Part2"], ["Part2", "Part3"]]
# - They match! Assembly is complete.
# -----------------------------------------------------------------------------
func _check_assembly() -> void:
	# Create sorted copies for comparison (don't modify originals)
	# duplicate(true) creates a deep copy, including nested arrays
	var sorted_solution = solution.duplicate(true)
	sorted_solution.sort()
	var sorted_actual = part_connections.duplicate(true)
	sorted_actual.sort()

	# --- DEBUG: Uncomment these lines to see what's being compared ---
	#print("Solution: ", sorted_solution, " types: ", typeof(sorted_solution[0][0]))
	#if sorted_actual.size() > 0 and sorted_actual[0].size() > 0:
	#	print("Actual: ", sorted_actual, " types: ", typeof(sorted_actual[0][0]))
	#else:
	#	print("Actual: ", sorted_actual, " (empty)")
	# -----------------------------------------------------------------

	# Check if player's connections match the solution exactly
	if sorted_actual == sorted_solution:
		print("Assembly complete")
		# TODO: Add your victory logic here (play sound, show UI, etc.)
