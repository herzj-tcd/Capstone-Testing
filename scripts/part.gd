extends Node2D

# =============================================================================
# PART.GD - Draggable Connectable Part
# =============================================================================
# This script handles the behavior of a single draggable part that can snap
# and connect to other parts. Each part has multiple connector areas (Area2D
# nodes) that detect when they overlap with connectors from other parts.
#
# How it works:
# 1. Player clicks and holds on the part to start dragging
# 2. While dragging, the part follows the mouse
# 3. If a connector overlaps with another part's connector, a snap target is set
# 4. When the player releases, the part snaps to the target position
# 5. Signals are emitted to notify the main scene of connections/disconnections
#
# Scene structure expected:
# - Part (Node2D with this script)
#   - Sprite2D (visual representation)
#   - Button (invisible button for click detection)
#   - Connector (Area2D at edge of part)
#   - Connector2 (Area2D at another edge)
#   - ... (more connectors as needed)
# =============================================================================


# =============================================================================
# SIGNALS
# =============================================================================
# Signals are emitted to notify parent nodes (like main.gd) when connections
# change. The parent can connect to these signals to track assembly state.
#
# Parameters for both signals:
# - this_part: Reference to this part (the one emitting the signal)
# - other_part: Reference to the part being connected to / disconnected from
# =============================================================================

# Emitted when this part successfully snaps to another part
signal parts_connected(this_part, other_part)

# Emitted when this part is dragged away from a connected part
signal parts_disconnected(this_part, other_part)


# =============================================================================
# STATE VARIABLES
# =============================================================================

# Whether the part is currently being dragged by the player
# Set to true when mouse button is pressed, false when released
var being_dragged := false

# The offset between the mouse position and the part's position when dragging started
# This prevents the part from "jumping" to center on the mouse cursor
# Example: If you click on the edge of a part, it stays under your cursor correctly
var mouse_offset := Vector2(0, 0)

# The position this part will snap to when released (if a valid connection exists)
# Set when connectors overlap, cleared when they separate or after snapping
# null means no snap target (part stays where released)
var snap_target = null

# Reference to the part this one is currently connected to (or about to connect to)
# Used to emit the correct signal and track connection state
# null means not connected to anything
var connected_to = null


# =============================================================================
# INITIALIZATION
# =============================================================================
func _ready() -> void:
	# Dynamically connect area_exited signals for all connector Area2D nodes
	# This allows us to detect when the player drags away before releasing
	#
	# Why dynamic connection?
	# - Works automatically with any number of connectors
	# - Don't need to manually connect each one in the editor
	# - Keeps the part self-contained and reusable
	for child in get_children():
		if child is Area2D:
			# When this connector stops overlapping with another, call our handler
			child.area_exited.connect(_on_connector_area_exited)


# =============================================================================
# MAIN LOOP
# =============================================================================
func _process(_delta: float) -> void:
	if being_dragged:
		# DRAGGING STATE
		# Part follows the mouse, offset by where it was originally clicked
		# This keeps the part "attached" to the cursor at the same relative point
		position = get_global_mouse_position() - mouse_offset
	else:
		# RELEASED STATE
		# Check if we have a snap target (meaning connectors were overlapping)
		if snap_target != null:
			# Snap the part to the calculated position
			position = snap_target

			# Notify listeners that a connection was made
			parts_connected.emit(self, connected_to)
			#print("Emitting parts_connected: ", self.name, " -> ", connected_to.name)  # DEBUG

			# Clear snap target so we don't keep emitting signals
			# (connected_to stays set to track the ongoing connection)
			snap_target = null


# =============================================================================
# INPUT HANDLERS
# =============================================================================

# -----------------------------------------------------------------------------
# _on_button_button_down()
# -----------------------------------------------------------------------------
# Called when the player presses the mouse button on this part's Button node.
# Starts the dragging process and breaks any existing connection.
# -----------------------------------------------------------------------------
func _on_button_button_down() -> void:
	# Start dragging
	being_dragged = true

	# Calculate offset so part doesn't jump to mouse position
	# Example: Click on right edge -> offset is positive X -> part stays right of cursor
	mouse_offset = get_global_mouse_position() - global_position

	# If we were connected to another part, break that connection
	if connected_to != null:
		# Store reference before clearing (needed for signal)
		var old = connected_to
		connected_to = null

		# Notify listeners that the connection was broken
		parts_disconnected.emit(self, old)


# -----------------------------------------------------------------------------
# _on_button_button_up()
# -----------------------------------------------------------------------------
# Called when the player releases the mouse button.
# Stops dragging - the actual snapping happens in _process on the next frame.
# -----------------------------------------------------------------------------
func _on_button_button_up() -> void:
	being_dragged = false
	# Note: Snapping and signal emission happen in _process()
	# This ensures the snap only happens once, on the frame after release


# =============================================================================
# CONNECTOR COLLISION HANDLERS
# =============================================================================

# -----------------------------------------------------------------------------
# _on_connector_area_entered(area)
# -----------------------------------------------------------------------------
# Called when one of this part's connectors overlaps with another Area2D.
# Sets up the snap target so the part will snap into place when released.
#
# Parameters:
# - area: The Area2D that was entered (belongs to another part)
#
# Snap position calculation:
# - Start with the other part's position
# - Add the connector's local position * 2 to offset correctly
# - This works because connectors are at the edges (e.g., at x=64)
# - Multiplying by 2 positions this part so edges align perfectly
# -----------------------------------------------------------------------------
func _on_connector_area_entered(area: Area2D) -> void:
	# Only set snap target if we're currently dragging
	# (Prevents snapping when another part is dragged onto this one)
	if being_dragged:
		# Get the part that owns the connector we touched
		connected_to = area.get_parent()

		# Calculate where this part should snap to
		# Start at the other part's position
		snap_target = connected_to.position
		# Offset based on connector position to align edges
		# The *2 accounts for both parts' connector offsets
		snap_target += area.position * 2


# -----------------------------------------------------------------------------
# _on_connector_area_exited(area)
# -----------------------------------------------------------------------------
# Called when one of this part's connectors stops overlapping with another Area2D.
# Clears the snap target if the player drags away before releasing.
#
# Parameters:
# - area: The Area2D that was exited (belongs to another part)
#
# This prevents "sticky" connections where:
# 1. Player drags over a connector (snap_target set)
# 2. Player drags away without releasing
# 3. Player releases elsewhere
# 4. Without this handler, part would snap back to old target!
# -----------------------------------------------------------------------------
func _on_connector_area_exited(area: Area2D) -> void:
	# Only clear if we're dragging AND this was our intended connection target
	# The second check prevents clearing when exiting a different part's connector
	if being_dragged and connected_to == area.get_parent():
		connected_to = null
		snap_target = null
