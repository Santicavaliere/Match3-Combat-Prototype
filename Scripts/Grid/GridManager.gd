extends Node2D

class_name GridManager

# --- CONFIGURACIÓN ---
@export var width: int = 7
@export var height: int = 9
@export var offset: int = 70 # Tamaño de la celda (en píxeles) para saber dónde dibujar luego
@export var y_offset: int = 2 # Margen superior extra
@export var piece_scene: PackedScene # Aquí arrastraremos la escena Piece.tscn
# --- DATOS (La Matriz) ---
# Usaremos un Array de Arrays.
# grid_data[x][y] nos dará la información de qué pieza hay en esa coordenada.
var grid_data: Array = [] 
# --- VARIABLES NUEVAS PARA EL SWAP ---
var first_selected: Piece = null
var second_selected: Piece = null
var is_processing: bool = false # Bloqueo para que no toquen mientras se mueven
# --- INICIALIZACIÓN ---
func _ready():
	# Inicializamos la semilla aleatoria para que cada partida sea distinta
	randomize() 
	
	# Creamos el tablero en memoria
	grid_data = make_2d_array()
	spawn_pieces()
	
	# DEBUG: Imprimimos la matriz en la consola para verificar
	print_grid_to_console()

# Paso A: Crear la estructura vacía
func make_2d_array() -> Array:
	var array = []
	for i in width:
		array.append([]) # Agregamos una columna vacía
		for j in height:
			array[i].append(null) # Llenamos la columna con 'null' (huecos vacíos)
	return array

# Paso B: Rellenar con piezas (evitando matches iniciales)
func spawn_pieces():
	for x in width:
		for y in height:
			# ... (Tu lógica de generación aleatoria y anti-match) ...
			var possible_type = randi() % 4
			while _match_is_possible(x, y, possible_type):
				possible_type = randi() % 4
			
			grid_data[x][y] = possible_type
			
			# Instanciamos la pieza visual
			var piece = piece_scene.instantiate()
			add_child(piece)
			
			var pixel_x = x * offset + 35
			var pixel_y = y * offset + 35 + (y_offset * offset)
			piece.position = Vector2(pixel_x, pixel_y)
			
			piece.setup(x, y, possible_type)
			
			# --- CONEXIÓN DE SEÑAL IMPORTANTE ---
			# Conectamos la señal personalizada que creamos en Piece.gd
			if not piece.piece_selected.is_connected(_on_piece_clicked):
				piece.piece_selected.connect(_on_piece_clicked)

# Helper: Verifica si poner 'type' en (x,y) crearía un match inmediato
func _match_is_possible(x, y, type) -> bool:
	# Chequeo Horizontal (Miro las 2 a la izquierda)
	if x > 1:
		if grid_data[x-1][y] == type and grid_data[x-2][y] == type:
			return true
	
	# Chequeo Vertical (Miro las 2 de abajo - nota: generamos de arriba a abajo o viceversa, 
	# pero como estamos llenando el array, miramos las que YA existen, o sea y-1 e y-2)
	if y > 1:
		if grid_data[x][y-1] == type and grid_data[x][y-2] == type:
			return true
			
	return false

# --- LÓGICA DE INPUT Y SWAP ---

func _on_piece_clicked(piece: Piece):
	if is_processing: return # Si ya se están moviendo, ignoramos clics
	
	if first_selected == null:
		# PRIMER CLIC: Seleccionamos la primera pieza
		first_selected = piece
		# Opcional: Dale un pequeño cambio de escala o color para saber que está elegida
		first_selected.modulate = Color(1.2, 1.2, 1.2) # Brillo
		print("Seleccionada 1: ", piece.grid_x, ",", piece.grid_y)
		
	elif first_selected == piece:
		# CLIC EN LA MISMA: Deseleccionar
		first_selected.modulate = Color.WHITE
		first_selected = null
		print("Deseleccionada")
		
	else:
		# SEGUNDO CLIC: Intentamos intercambiar
		second_selected = piece
		print("Seleccionada 2: ", piece.grid_x, ",", piece.grid_y)
		
		# Verificamos si están pegadas (Vecinas)
		if _is_adjacent(first_selected, second_selected):
			# Quitamos el brillo a la primera
			first_selected.modulate = Color.WHITE
			swap_pieces(first_selected, second_selected)
		else:
			# Si están lejos, la segunda pasa a ser la nueva seleccionada
			first_selected.modulate = Color.WHITE
			first_selected = piece
			first_selected.modulate = Color(1.2, 1.2, 1.2)
			second_selected = null

func _is_adjacent(p1: Piece, p2: Piece) -> bool:
	var diff_x = abs(p1.grid_x - p2.grid_x)
	var diff_y = abs(p1.grid_y - p2.grid_y)
	# Solo son adyacentes si la suma de diferencias es 1 (no diagonales)
	return (diff_x + diff_y) == 1

func swap_pieces(p1: Piece, p2: Piece):
	is_processing = true # Bloqueamos input
	
	# 1. Intercambio en la MATRIZ DE DATOS (grid_data)
	var temp_type = grid_data[p1.grid_x][p1.grid_y]
	grid_data[p1.grid_x][p1.grid_y] = grid_data[p2.grid_x][p2.grid_y]
	grid_data[p2.grid_x][p2.grid_y] = temp_type
	
	# 2. Intercambio de VARIABLES en las piezas
	var temp_x = p1.grid_x
	var temp_y = p1.grid_y
	
	p1.grid_x = p2.grid_x
	p1.grid_y = p2.grid_y
	
	p2.grid_x = temp_x
	p2.grid_y = temp_y
	
	# 3. Animación Visual (TWEEN)
	var tween = create_tween()
	tween.set_parallel(true) # Mover ambas a la vez
	tween.tween_property(p1, "position", p2.position, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(p2, "position", p1.position, 0.3).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	
# --- NUEVA LÓGICA DE DESTRUCCIÓN ---
	var matches = find_matches() # Ahora esto devuelve una lista
	
	if matches.size() > 0:
		# ¡Hubo match! Destruimos las piezas
		destroy_matches(matches)
		# Nota: destroy_matches se encarga de poner is_processing = false al final
	else:
		# NO hubo match -> Revertimos
		swap_back(p1, p2)
	
	first_selected = null
	second_selected = null

func swap_back(p1: Piece, p2: Piece):
	print("Movimiento inválido - Regresando...")
	# Hacemos exactamente lo mismo que swap_pieces pero SIN llamar a checkear matches al final
	
	# 1. Revertir Datos
	var temp_type = grid_data[p1.grid_x][p1.grid_y]
	grid_data[p1.grid_x][p1.grid_y] = grid_data[p2.grid_x][p2.grid_y]
	grid_data[p2.grid_x][p2.grid_y] = temp_type
	
	# 2. Revertir Variables
	var temp_x = p1.grid_x
	var temp_y = p1.grid_y
	p1.grid_x = p2.grid_x
	p1.grid_y = p2.grid_y
	p2.grid_x = temp_x
	p2.grid_y = temp_y
	
	# 3. Revertir Animación
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(p1, "position", p2.position, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(p2, "position", p1.position, 0.3).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	
	is_processing = false # Desbloqueamos el input recién ahora

# --- DEBUG ---
# Esta función es vital. Te permite "ver" el tablero sin gráficos.
func print_grid_to_console():
	print("--- MAPA GENERADO ---")
	# Imprimimos fila por fila (invertimos Y para que se vea visualmente correcto en log)
	for y in range(height):
		var row_string = ""
		for x in range(width):
			row_string += str(grid_data[x][y]) + " "
		print(row_string)
	print("---------------------")

# --- MODIFICACIÓN: Ahora devuelve un Array (lista de coordenadas) ---
func find_matches() -> Array:
	var matches_found = [] 
	
	# 1. Búsqueda Horizontal
	for y in height:
		for x in range(width - 2):
			var type1 = grid_data[x][y]
			var type2 = grid_data[x+1][y]
			var type3 = grid_data[x+2][y]
			
			if type1 != null and type1 == type2 and type1 == type3:
				matches_found.append(Vector2(x, y))
				matches_found.append(Vector2(x+1, y))
				matches_found.append(Vector2(x+2, y))

	# 2. Búsqueda Vertical
	for x in width:
		for y in range(height - 2):
			var type1 = grid_data[x][y]
			var type2 = grid_data[x][y+1]
			var type3 = grid_data[x][y+2]
			
			if type1 != null and type1 == type2 and type1 == type3:
				matches_found.append(Vector2(x, y))
				matches_found.append(Vector2(x, y+1))
				matches_found.append(Vector2(x, y+2))

	# Devolvemos la lista (si está vacía, funciona como false en condiciones)
	return matches_found

func destroy_matches(matches: Array):
	print("Destruyendo ", matches.size(), " piezas...")
	
	for coord in matches:
		# 1. Borrar de la Matriz de Datos (Lógica)
		# Si ya es null, saltamos (para no borrar dos veces la misma si se cruzan matches)
		if grid_data[coord.x][coord.y] == null:
			continue
			
		grid_data[coord.x][coord.y] = null # Dejamos el hueco vacío
		
		# 2. Borrar la Pieza Visual
		# Como no guardamos la pieza en la matriz, la buscamos por fuerza bruta
		# (Para un prototipo esto está bien y es rápido)
		var piece_to_delete = _get_piece_at(coord.x, coord.y)
		if piece_to_delete:
			# Animación simple de desaparición
			var tween = create_tween()
			tween.tween_property(piece_to_delete, "scale", Vector2.ZERO, 0.2)
			tween.tween_callback(piece_to_delete.queue_free) # La eliminamos de la memoria al terminar
	
	# Esperamos un poco a que desaparezcan visualmente
	await get_tree().create_timer(0.3).timeout
	
	# EN LUGAR DE DESBLOQUEAR, LLAMAMOS A REFILL
	# is_processing = false  <-- BORRA O COMENTA ESTA LÍNEA
	
	refill_columns() # <-- LA NUEVA LLAMADA

	# Importante: Desbloquear el juego después de destruir
	# (Aquí más adelante llamaremos a la función "CAER" / Cascade)
	await get_tree().create_timer(0.3).timeout # Esperamos la animación
	print("Destrucción terminada.")
	is_processing = false 

# Helper para encontrar la pieza visual
func _get_piece_at(target_x: int, target_y: int) -> Piece:
	for child in get_children():
		if child is Piece:
			if child.grid_x == target_x and child.grid_y == target_y:
				return child
	return null

func refill_columns():
	print("Rellenando tablero...")
	var tween = create_tween()
	tween.set_parallel(true) # Que caigan todas a la vez
	
	for x in width:
		# 1. Recolectar las piezas que sobrevivieron en esta columna
		var column_pieces = []
		for y in height:
			# Si la celda NO es null, buscamos la pieza visual y la guardamos
			if grid_data[x][y] != null:
				var p = _get_piece_at(x, y)
				if p: 
					column_pieces.append(p)
		
		# 2. Calcular cuántas faltan para llenar la columna
		var pieces_needed = height - column_pieces.size()
		
		# 3. Crear las piezas nuevas (arriba de la pantalla)
		for i in pieces_needed:
			var type = randi() % 4
			# Instanciar
			var new_piece = piece_scene.instantiate()
			add_child(new_piece)
			
			# Posición de nacimiento (fuera de pantalla, arriba)
			# Calculamos una altura negativa para que caigan desde el cielo
			var spawn_y_pixel = (y_offset * offset) - (offset * (pieces_needed - i)) - 50
			var target_x_pixel = x * offset + 35
			new_piece.position = Vector2(target_x_pixel, spawn_y_pixel)
			
			# Configurar (Importante: conectar señal de click)
			new_piece.setup(x, -1, type) # -1 temporal
			new_piece.piece_selected.connect(_on_piece_clicked)
			
			# Agregamos la nueva pieza AL PRINCIPIO de la lista (porque va arriba)
			column_pieces.push_front(new_piece)
			
		# 4. Reasignar todo a la Matriz y Animar caída
		for y in height:
			var piece = column_pieces[y]
			
			# Actualizar DATOS
			grid_data[x][y] = piece.type
			
			# Actualizar PIEZA
			piece.grid_x = x
			piece.grid_y = y
			piece.name = "Piece_" + str(x) + "_" + str(y) # Opcional: para debug visual en el editor
			
			# Posición Destino Real
			var target_pos = Vector2(x * offset + 35, y * offset + 35 + (y_offset * offset))
			
			# Animar si no está en su sitio
			if piece.position != target_pos:
				tween.tween_property(piece, "position", target_pos, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Esperar a que terminen de caer
	await tween.finished
	print("Caída terminada.")
	
	# --- PASO 5: RECURSIVIDAD (Chain Reactions) ---
	# Una vez que cayeron, ¿se formaron nuevos matches por casualidad?
	var new_matches = find_matches()
	if new_matches.size() > 0:
		print("¡Reacción en cadena! Destruyendo de nuevo...")
		destroy_matches(new_matches)
	else:
		# Si no hay más matches, desbloqueamos el juego para que el jugador juegue
		is_processing = false
		print("Turno finalizado. Jugador puede mover.")
