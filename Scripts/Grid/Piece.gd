extends Node2D

class_name Piece

# Señal personalizada para avisar al GridManager
signal piece_selected(piece_ref)

# Variables de identidad
var type: int
var grid_x: int
var grid_y: int

@onready var sprite = $Sprite2D

func setup(tx: int, ty: int, t_type: int):
	grid_x = tx
	grid_y = ty
	type = t_type
	# Tu código de colores existente...
	match type:
		0: sprite.modulate = Color.RED
		1: sprite.modulate = Color.BLUE
		2: sprite.modulate = Color.GREEN
		3: sprite.modulate = Color.YELLOW

# --- ESTA ES LA FUNCIÓN QUE CONECTASTE DESDE EL AREA2D ---
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# Detectamos clic izquierdo (o toque en pantalla)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Click en pieza: ", grid_x, ",", grid_y) # Debug útil
		emit_signal("piece_selected", self)
