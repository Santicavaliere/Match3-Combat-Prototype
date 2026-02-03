extends Node2D

class_name Piece

## INDIVIDUAL GRID PIECE
##
## Represents a single tile on the Match-3 board.
## Handles its own visual state (Color/Sprite), input detection (Click/Swipe),
## and logical state (Locked/Unlocked).

# --- SIGNALS ---
signal piece_selected(piece_ref)
signal piece_swiped(piece_ref, direction)

# --- VARIABLES ---
var type: int
var grid_x: int
var grid_y: int

# --- NEW VARIABLES ---
## If true, this piece cannot be moved or swapped (used by 'Outlaw' ability).
var is_locked: bool = false 

@onready var sprite = $Sprite2D

# --- IMPROVED INPUT VARIABLES ---
var start_touch_pos = Vector2.ZERO
var is_dragging = false
var drag_threshold = 20.0 

## Initializes the piece data and visual appearance.
## @param tx: X Coordinate in the Grid.
## @param ty: Y Coordinate in the Grid.
## @param t_type: Integer ID representing the element type (0: Red, 1: Blue, etc.).
func setup(tx: int, ty: int, t_type: int):
	grid_x = tx
	grid_y = ty
	type = t_type
	match type:
		0: sprite.modulate = Color.RED
		1: sprite.modulate = Color.BLUE
		2: sprite.modulate = Color.GREEN
		3: sprite.modulate = Color.YELLOW

# 1. INITIAL DETECTION (Supports Mouse AND Native Touch)
## Callback for input events on the Area2D.
## Detects the start of a touch or mouse click to begin the drag operation.
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# Detect Mouse (PC) OR Touch (Mobile)
	var is_click = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_click = true
	elif event is InputEventScreenTouch and event.pressed:
		is_click = true
		
	if is_click:
		is_dragging = true
		start_touch_pos = get_global_mouse_position() # Works for both in Godot
		
		# Visual feedback: Scale up slightly when selected
		scale = Vector2(1.1, 1.1) 
		piece_selected.emit(self)

# 2. GLOBAL TRACKING (Supports Mouse AND Native Touch)
## Global input handler to track movement after the initial click.
## Handles the drag logic and detects when the input is released.
func _input(event):
	if not is_dragging:
		return
	
	# Detect RELEASE (Mouse or Touch)
	var is_release = false
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_release = true
	elif event is InputEventScreenTouch and not event.pressed:
		is_release = true
		
	if is_release:
		stop_dragging()

	# Detect DRAG (Mouse or Touch)
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		var current_pos = get_global_mouse_position()
		var difference = current_pos - start_touch_pos
		
		if difference.length() > drag_threshold:
			calculate_direction(difference)

## determines the primary direction of the swipe (Horizontal vs Vertical).
## Emits the 'piece_swiped' signal if a valid direction is detected.
func calculate_direction(difference: Vector2):
	var direction = Vector2.ZERO
	
	if abs(difference.x) > abs(difference.y):
		direction.x = sign(difference.x) 
	else:
		direction.y = sign(difference.y) 
	
	if direction != Vector2.ZERO:
		piece_swiped.emit(self, direction)
		stop_dragging() 

## Resets the dragging state and restores the visual scaling.
func stop_dragging():
	is_dragging = false
	scale = Vector2(1.0, 1.0)

## Sets the locked state of the piece (used by mechanics like the 'Outlaw' ability).
## Updates the visual feedback: Gray/Small if locked, Normal color if unlocked.
func set_locked(locked: bool):
	is_locked = locked
	if is_locked:
		# Visual Feedback: Dark gray and smaller (CHAINED)
		sprite.modulate = Color(0.4, 0.4, 0.4) 
		scale = Vector2(0.9, 0.9)
	else:
		# UNLOCKING: Restore original color based on type ID
		match type:
			0: sprite.modulate = Color.RED
			1: sprite.modulate = Color.BLUE
			2: sprite.modulate = Color.GREEN
			3: sprite.modulate = Color.YELLOW
		scale = Vector2(1.0, 1.0)
