extends Node2D

class_name Piece

# --- SIGNALS ---
signal piece_selected(piece_ref)
signal piece_swiped(piece_ref, direction)

# --- VARIABLES ---
var type: int
var grid_x: int
var grid_y: int

@onready var sprite = $Sprite2D

# --- IMPROVED INPUT VARIABLES ---
## Stores the global position where the touch/click started.
var start_touch_pos = Vector2.ZERO
## Flag to track if the player is currently holding this piece.
var is_dragging = false
## Minimum distance (in pixels) the finger must move to register a swipe.
var drag_threshold = 20.0 

func setup(tx: int, ty: int, t_type: int):
	grid_x = tx
	grid_y = ty
	type = t_type
	match type:
		0: sprite.modulate = Color.RED
		1: sprite.modulate = Color.BLUE
		2: sprite.modulate = Color.GREEN
		3: sprite.modulate = Color.YELLOW

# 1. INITIAL DETECTION (Triggered only when touching INSIDE the collision shape)
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = true
		start_touch_pos = get_global_mouse_position()
		
		scale = Vector2(1.1, 1.1) 
		piece_selected.emit(self)

# 2. GLOBAL TRACKING (Tracks movement even if the finger leaves the piece area)
func _input(event):
	if not is_dragging:
		return
	
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stop_dragging()

	elif event is InputEventMouseMotion:
		var current_pos = get_global_mouse_position()
		var difference = current_pos - start_touch_pos
		
		if difference.length() > drag_threshold:
			calculate_direction(difference)

## Determines the primary direction of the swipe (Horizontal vs Vertical).
## Emits the swipe signal and stops the drag interaction immediately.
func calculate_direction(difference: Vector2):
	var direction = Vector2.ZERO
	
	if abs(difference.x) > abs(difference.y):
		direction.x = sign(difference.x) 
	else:
		direction.y = sign(difference.y) 
	
	if direction != Vector2.ZERO:
		piece_swiped.emit(self, direction)
		stop_dragging() 

## Resets the dragging state and visual scaling.
func stop_dragging():
	is_dragging = false
	scale = Vector2(1.0, 1.0) 
