extends Node2D

class_name Piece

## INDIVIDUAL GRID PIECE
## Represents a single tile on the Match-3 board.

# --- SIGNALS ---
signal piece_selected(piece_ref)
signal piece_swiped(piece_ref, direction)

# --- VARIABLES ---
var type: int
var grid_x: int
var grid_y: int
var is_locked: bool = false 
var chain_sprite: Sprite2D
const CHAIN_TEX = preload("res://Assets/Final/UI/cadenas bloqueo de bombas.png") 

@onready var sprite = $Sprite2D
@onready var selection_vfx = $SelectionVFX

# --- CONFIGURACIÓN DE TAMAÑO ---
# Ajusta esto si quieres que sean un poco más grandes o chicos (60.0 es ideal para celdas de 64)
const TARGET_SIZE = 44.0 

# --- TEXTURE LOADING ---
const TEXTURES = {
	# Mantenemos TODOS los iconos viejos del Grid por seguridad
	# hasta que Edison mande los reemplazos exactos (cuadrados).
	
	0: preload("res://Assets/Icons/Grid/Rubi rojo.png"),      
	1: preload("res://Assets/Icons/Grid/Zafiro azul.png"), 
	2: preload("res://Assets/Icons/Grid/esmeralda.png"),   
	
	# REVERTIDO: Usamos el icono de bomba original del grid.
	# "bomba bala de canon juego.png" parece ser el proyectil, no la ficha.
	3: preload("res://Assets/Icons/Grid/bomba grid (1).png"), 
	
	# REVERTIDO: Usamos el icono de timón original.
	# "TIMON BAR.png" es la barra de UI, no la ficha.
	4: preload("res://Assets/Icons/Grid/timon (1).png"), 
	
	5: preload("res://Assets/Icons/Grid/gold.png"),       
	6: preload("res://Assets/Icons/Grid/pergasamino ico.png")      
}

# --- INPUT VARIABLES ---
var start_touch_pos = Vector2.ZERO
var is_dragging = false
var drag_threshold = 20.0 

## Initializes the piece data and visual appearance.
func setup(tx: int, ty: int, t_type: int):
	grid_x = tx
	grid_y = ty
	type = t_type
	
	# --- VISUAL UPDATE ---
	sprite.modulate = Color.WHITE
	
	
	if not chain_sprite:
		chain_sprite = Sprite2D.new()
		chain_sprite.texture = CHAIN_TEX
		chain_sprite.hide()
		chain_sprite.z_index = 10 # Asegura que se dibuje por encima de la gema
		add_child(chain_sprite)
		
		
		var tex_size = CHAIN_TEX.get_size()
		var max_side = max(tex_size.x, tex_size.y)
		if max_side > TARGET_SIZE:
			var scale_factor = TARGET_SIZE / max_side
			chain_sprite.scale = Vector2(scale_factor, scale_factor)
	
	
	if TEXTURES.has(type):
		var tex = TEXTURES[type]
		sprite.texture = tex
		
		# --- AUTO-SCALING LOGIC ---
		# Forzamos que la imagen quepa en 60x60 píxeles
		var tex_size = tex.get_size()
		var max_side = max(tex_size.x, tex_size.y)
		
		if max_side > TARGET_SIZE:
			var scale_factor = TARGET_SIZE / max_side
			sprite.scale = Vector2(scale_factor, scale_factor)
		else:
			sprite.scale = Vector2(1.0, 1.0)
			
	else:
		print("ERROR: No texture found for Piece Type: ", type)
		sprite.modulate = Color.MAGENTA 
	
	# --- EL FIX DEL VFX (VERSIÓN FINAL) ---
	if selection_vfx:
		selection_vfx.hide() # Volvemos a ocultarlo
		selection_vfx.z_index = 100 # Lo dejamos bien alto
		
		if selection_vfx.sprite_frames:
			selection_vfx.sprite_frames.set_animation_loop("default", true)

# ==========================================
#      LÓGICA DE INPUT (RECUPERADA)
# ==========================================

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	var is_click = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_click = true
	elif event is InputEventScreenTouch and event.pressed:
		is_click = true
		
	# --- EL FIX DEL CLIC FANTASMA ---
	# Solo procesamos el clic si NO estábamos arrastrando ya
	if is_click and not is_dragging:
		is_dragging = true
		start_touch_pos = get_global_mouse_position()
		
		piece_selected.emit(self)

# 2. SEGUIMIENTO GLOBAL (Arrastrar)
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

	# Detectar MOVIMIENTO (Mouse o Touch)
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		var current_pos = get_global_mouse_position()
		var difference = current_pos - start_touch_pos
		
		if difference.length() > drag_threshold:
			calculate_direction(difference)

# 3. CÁLCULO DE DIRECCIÓN
func calculate_direction(difference: Vector2):
	var direction = Vector2.ZERO
	
	if abs(difference.x) > abs(difference.y):
		direction.x = sign(difference.x) 
	else:
		direction.y = sign(difference.y) 
	
	if direction != Vector2.ZERO:
		piece_swiped.emit(self, direction)
		stop_dragging() 

# 4. RESETEAR ESTADO
func stop_dragging():
	is_dragging = false
	
	# FIX: Solo volver a 1.0 si NO está el aura mágica encendida
	if selection_vfx and selection_vfx.visible:
		scale = Vector2(1.1, 1.1)
	else:
		scale = Vector2(1.0, 1.0)

# 5. BLOQUEO (Para habilidades como Outlaw)
func set_locked(locked: bool):
	is_locked = locked
	if is_locked:
		sprite.modulate = Color(0.4, 0.4, 0.4) 
		# Reducimos un poquito la escala visual actual
		scale = Vector2(0.9, 0.9)
		if chain_sprite: chain_sprite.show()
	else:
		sprite.modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)
		if chain_sprite: chain_sprite.hide()

func set_selected(active: bool):
	if active:
		print("✅ ENCENDIENDO anillo mágico en la ficha: ", grid_x, ",", grid_y)
		scale = Vector2(1.1, 1.1)
		if selection_vfx:
			selection_vfx.show()
			selection_vfx.play("default")
	else:
		print("❌ APAGANDO anillo mágico en la ficha: ", grid_x, ",", grid_y)
		scale = Vector2(1.0, 1.0)
		if selection_vfx:
			selection_vfx.hide()
			selection_vfx.stop()
