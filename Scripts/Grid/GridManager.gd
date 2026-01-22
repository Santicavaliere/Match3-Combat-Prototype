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
			var possible_type = randi() % 4
			
			while _match_is_possible(x, y, possible_type):
				possible_type = randi() % 4
			
			# 1. Guardamos en DATOS
			grid_data[x][y] = possible_type
			
			# 2. Creamos VISUALIZACIÓN
			var piece = piece_scene.instantiate()
			add_child(piece)
			
			# Calculamos la posición en pixeles
			# offset es el tamaño de la celda.
			# Sumamos medio offset si quieres centrarlo, o dejalo así para esquina sup-izq.
			var pixel_x = x * offset + 35 # +35 es la mitad de 70 para centrar
			var pixel_y = y * offset + 35 + (y_offset * offset) # Bajamos un poco el tablero
			
			piece.position = Vector2(pixel_x, pixel_y)
			
			# Configuramos la pieza
			piece.setup(x, y, possible_type)
			
			# Guardamos la referencia visual en el array (Opcional pero útil luego)
			# Por ahora el array grid_data solo tiene números (int).
			# Mas adelante convertiremos grid_data para guardar OBJETOS, 
			# pero por hoy dejemos solo la visualización.

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
