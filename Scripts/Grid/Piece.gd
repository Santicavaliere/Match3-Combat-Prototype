extends Node2D

class_name Piece

# Variables para saber qué soy y dónde estoy
var type: int # 0, 1, 2, 3...
var grid_x: int
var grid_y: int

@onready var sprite = $Sprite2D

# Función para "pintar" la pieza según su tipo
func setup(tx: int, ty: int, t_type: int):
	grid_x = tx
	grid_y = ty
	type = t_type
	
	# CAMBIO DE COLOR TEMPORAL (Para diferenciar tipos sin tener assets)
	match type:
		0: sprite.modulate = Color.RED
		1: sprite.modulate = Color.BLUE
		2: sprite.modulate = Color.GREEN
		3: sprite.modulate = Color.YELLOW
		_: sprite.modulate = Color.WHITE
