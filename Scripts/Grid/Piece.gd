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

# --- VARIABLES NUEVAS PARA EL DRAG ---
var start_touch_pos = Vector2.ZERO
var is_dragging = false
var drag_threshold = 30.0 # Cuántos píxeles hay que mover el dedo para que cuente

# Señal nueva para avisarle al GridManager hacia dónde fuimos
signal piece_swiped(piece_ref, direction)

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


func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# 1. Cuando empezamos a tocar (Press)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = true
		start_touch_pos = get_global_mouse_position()
		# Opcional: Seleccionar visualmente la pieza si quieres
		piece_selected.emit(self) 

	# 2. Cuando soltamos el click (Release)
	elif event is InputEventMouseButton and not event.pressed:
		is_dragging = false

	# 3. Mientras movemos el dedo/mouse (Drag)
	elif event is InputEventMouseMotion and is_dragging:
		var current_pos = get_global_mouse_position()
		var difference = current_pos - start_touch_pos
		
		# Si movimos el dedo más allá del umbral...
		if difference.length() > drag_threshold:
			# Calculamos la dirección principal (Arriba, Abajo, Izq, Der)
			var direction = Vector2.ZERO
			
			if abs(difference.x) > abs(difference.y):
				# Movimiento Horizontal
				direction.x = sign(difference.x) # 1 (Derecha) o -1 (Izquierda)
			else:
				# Movimiento Vertical
				direction.y = sign(difference.y) # 1 (Abajo) o -1 (Arriba)
			
			# ¡Enviamos la señal y dejamos de arrastrar!
			piece_swiped.emit(self, direction)
			is_dragging = false
