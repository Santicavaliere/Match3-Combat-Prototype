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
var start_touch_pos = Vector2.ZERO
var is_dragging = false
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

# 1. INITIAL DETECTION (Soporta Mouse Y Touch nativo)
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# Detectar Mouse (PC) O Touch (Celular)
	var is_click = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_click = true
	elif event is InputEventScreenTouch and event.pressed:
		is_click = true
		
	if is_click:
		is_dragging = true
		start_touch_pos = get_global_mouse_position() # Funciona para ambos en Godot
		
		scale = Vector2(1.1, 1.1) 
		piece_selected.emit(self)

# 2. GLOBAL TRACKING (Soporta Mouse Y Touch nativo)
func _input(event):
	if not is_dragging:
		return
	
	# Detectar SOLTAR (Mouse o Touch)
	var is_release = false
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_release = true
	elif event is InputEventScreenTouch and not event.pressed:
		is_release = true
		
	if is_release:
		stop_dragging()

	# Detectar ARRASTRE (Mouse o Touch)
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		var current_pos = get_global_mouse_position()
		var difference = current_pos - start_touch_pos
		
		if difference.length() > drag_threshold:
			calculate_direction(difference)

## Determines the primary direction of the swipe (Horizontal vs Vertical).
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
