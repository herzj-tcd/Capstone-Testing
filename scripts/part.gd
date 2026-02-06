extends Node2D

signal parts_connected(this_part, other_part)
signal parts_disconnected(this_part, other_part)

var being_dragged := false # whether the part is being dragged with the mouse
var mouse_offset := Vector2(0, 0) # the vector between the coordinates of the part and where it was clicked with the mouse to drag

var snap_target = null # stores the positions of the snap_targeted parts and their offsets
var connected_to = null
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	# moves the part around when it's being dragged
	if being_dragged:
		position = get_global_mouse_position() - mouse_offset
	#snaps the parts together visually
	else:
		if snap_target != null:
			position = snap_target
			snap_target = null
			print("part connected")

# starts dragging the part when the button is held
func _on_button_button_down() -> void:
	being_dragged = true
	mouse_offset = get_global_mouse_position() - global_position
	
	# breaks connections
	if connected_to != null:
		var old = connected_to
		connected_to = null
		parts_disconnected.emit(self, old)
		
# stops dragging the part when the button is released
func _on_button_button_up() -> void:
	being_dragged = false

# creates the connection
func _on_connector_area_entered(area: Area2D) -> void:
		if being_dragged:
			var other_part = area.get_parent()
			snap_target = other_part.position # problem here maybe
			snap_target += area.position * 2 
			connected_to = other_part
			parts_connected.emit(self, other_part)
