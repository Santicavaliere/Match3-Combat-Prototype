extends Node2D

## Represents a single interactive tile object in the Match-3 grid.
## Stores its own logical coordinates (Grid X, Y) and Type ID (Color).
## Handles input detection and communicates with the GridManager via signals.
class_name Piece

## Signal emitted when this specific piece is clicked or touched.
## Passing 'self' allows the GridManager to know exactly which instance was selected.
signal piece_selected(piece_ref)

var type: int
var grid_x: int
var grid_y: int

@onready var sprite = $Sprite2D

## Initializes the piece data and visual appearance.
## Called by GridManager immediately after instantiation.
## @param tx: Logical X coordinate.
## @param ty: Logical Y coordinate.
## @param t_type: Integer ID that determines the color.
func setup(tx: int, ty: int, t_type: int):
	grid_x = tx
	grid_y = ty
	type = t_type
	match type:
		0: sprite.modulate = Color.RED
		1: sprite.modulate = Color.BLUE
		2: sprite.modulate = Color.GREEN
		3: sprite.modulate = Color.YELLOW

## Input callback connected to the child Area2D node.
## Detects Left Mouse Button clicks OR Touch inputs on mobile.
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	var is_mouse_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	
	var is_touch_tap = event is InputEventScreenTouch and event.pressed
	
	if is_mouse_click or is_touch_tap:
		print("Input detected on piece: ", grid_x, ",", grid_y)
		piece_selected.emit(self) # Sintaxis moderna de Godot 4 para emitir señales
