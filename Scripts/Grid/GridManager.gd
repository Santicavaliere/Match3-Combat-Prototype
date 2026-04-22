extends Node2D

## Core system that manages the Match-3 grid logic.
##
## Handles procedural generation, the input state machine, swapping mechanics,
## match detection algorithms, the refill cascade (gravity), and deadlock prevention.
class_name GridManager

# --- CONFIGURATION ---
@export var width: int = 12
@export var height: int = 7
@export var offset_x: float = 56.0  # Horizontal spacing control
@export var offset_y: float = 52.0  # Vertical spacing control
@export var y_offset: int = 0 
@export var piece_scene: PackedScene

# --- DATA ---
## 2D Array storing the logical state of the grid (Integers representing IDs).
var grid_data: Array = [] 

# --- STATE MANAGEMENT ---
var first_selected: Piece = null
var second_selected: Piece = null
var is_processing: bool = false 
var is_game_over: bool = false
var is_enemy_turn: bool = false
var is_cascading: bool = false
var is_out_of_lives: bool = false

# --- TURN SYSTEM ---
var max_moves: int = 3
var current_moves: int = 0

## Standard Godot lifecycle method.
## Initializes the RNG, creates the grid data structure, spawns initial pieces,
## connects necessary signals for the game loop, and starts the first turn.
func _ready():
	randomize()
	grid_data = make_2d_array()
	
	# ¡Acá borramos el spawn_pieces() viejo que generaba el duplicado!
	
	SignalBus.enemy_turn_finished.connect(_on_enemy_finished)
	SignalBus.turn_ended.connect(_on_player_ended)
	SignalBus.game_over.connect(_on_game_over)
	
	if LifeManager.consume_life_to_play():
		print("¡Vida descontada! Iniciando partida...")
		spawn_pieces() # <-- AHORA SÍ, ESTE ES EL ÚNICO SPAWN
		reset_turn()
		
		print_grid_to_console()
	else:
		print("No hay vidas. Bloqueando inicio y mostrando tienda.")
		is_out_of_lives = true
		
		await get_tree().create_timer(0.1).timeout 
		SignalBus.show_lives_purchase_popup.emit()
		
	

## Resets the turn state, restoring action points and notifying the UI.
func reset_turn():
	current_moves = max_moves
	SignalBus.moves_updated.emit(current_moves)
	is_processing = false
	print("Turn Reset. Moves: ", current_moves)

## Initializes the empty 2D array structure to store tile data.
func make_2d_array() -> Array:
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

## Populates the grid with random pieces.
## Includes a validation check to ensure the initial board has NO pre-existing matches.
func spawn_pieces():
	for x in width:
		for y in height:
			var possible_type = _get_random_piece_type()
			while _match_is_possible(x, y, possible_type):
				possible_type = _get_random_piece_type()
			
			grid_data[x][y] = possible_type
			
			var piece = piece_scene.instantiate()
			add_child(piece)
			
			var pixel_x = x * offset_x + 35
			var pixel_y = y * offset_y + 35 + (y_offset * offset_y)
			
			piece.position = Vector2(pixel_x, pixel_y)
			piece.setup(x, y, possible_type)
			
			if not piece.piece_selected.is_connected(_on_piece_clicked):
				piece.piece_selected.connect(_on_piece_clicked)
			
			if not piece.piece_swiped.is_connected(_on_piece_swiped):
				piece.piece_swiped.connect(_on_piece_swiped)

## Helper function to check if placing a specific tile type at (x,y) would cause a match.
func _match_is_possible(x, y, type) -> bool:
	if x > 1:
		if grid_data[x-1][y] == type and grid_data[x-2][y] == type:
			return true
	
	if y > 1:
		if grid_data[x][y-1] == type and grid_data[x][y-2] == type:
			return true
			
	return false

## Input State Machine.
## Handles the First Click (Select) and Second Click (Swap) logic.
## Validates locks, Game Over state, and Turn state.
func _on_piece_clicked(piece: Piece):
	if is_game_over or is_enemy_turn or is_processing or is_out_of_lives: return
	
	if current_moves <= 0: return 
	
	if piece.is_locked:
		print("GridManager: This piece is locked/chained.")
		return 
	
	if first_selected == null:
		first_selected = piece
		first_selected.set_selected(true) # <-- EL FIX
		print("Selected 1: ", piece.grid_x, ",", piece.grid_y)
		
	elif first_selected == piece:
		# --- THE FIX MOBILE ---
		# Instead of turning off the circle and deselecting, we do NOTHING.
		# This keeps the magic circle on so the player can
		# initiate a smooth drag without visual flickering.
		print("Tap on the same card. Waiting for drag...")
		pass
		
	else:
		second_selected = piece
		print("Selected 2: ", piece.grid_x, ",", piece.grid_y)
		
		if _is_adjacent(first_selected, second_selected):
			first_selected.set_selected(false) 
			swap_pieces(first_selected, second_selected)
			first_selected = null
			second_selected = null
		else:
			first_selected.set_selected(false) 
			first_selected = piece
			first_selected.set_selected(true) 
			second_selected = null

## Checks if two pieces are immediate neighbors.
func _is_adjacent(p1: Piece, p2: Piece) -> bool:
	var diff_x = abs(p1.grid_x - p2.grid_x)
	var diff_y = abs(p1.grid_y - p2.grid_y)
	return (diff_x + diff_y) == 1

## Core Mechanic: Swaps two pieces in data and visually.
## Triggers match validation and consumes turn points.
func swap_pieces(p1: Piece, p2: Piece):
	is_processing = true 
	
	# 1. Swap Data
	var temp_type = grid_data[p1.grid_x][p1.grid_y]
	grid_data[p1.grid_x][p1.grid_y] = grid_data[p2.grid_x][p2.grid_y]
	grid_data[p2.grid_x][p2.grid_y] = temp_type
	
	# 2. Swap Grid Coordinates
	var temp_x = p1.grid_x
	var temp_y = p1.grid_y
	
	p1.grid_x = p2.grid_x
	p1.grid_y = p2.grid_y
	
	p2.grid_x = temp_x
	p2.grid_y = temp_y
	
	# 3. Swap Visuals (Animation)
	var tween = create_tween()
	tween.set_parallel(true) 
	tween.tween_property(p1, "position", p2.position, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(p2, "position", p1.position, 0.3).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	
	# Security check: Ensure pieces exist after animation
	if not is_instance_valid(p1) or not is_instance_valid(p2):
		is_processing = false
		return
	
	# 4. Validate Move
	var matches = find_matches()
	
	if matches.size() > 0:
		var unique_matches = []
		for coord in matches:
			if not unique_matches.has(coord):
				unique_matches.append(coord)
		
		var match_count = unique_matches.size()
		
		destroy_matches(matches)
		
		# Turn logic based on match count
		if match_count == 3:
			current_moves -= 1
			print("Match 3 - Consumed 1 move. Moves left: ", current_moves)
		elif match_count == 4:
			print("Match 4 - Free move! Moves left: ", current_moves)
			_show_floating_text("FREE MOVE!", Color.AQUA)
		elif match_count >= 5:
			current_moves += 1
			print("Match 5+ - Gained 1 move! Moves left: ", current_moves)
			_show_floating_text("EXTRA TURN!", Color.GOLD)
		
		SignalBus.moves_updated.emit(current_moves)
		
		if current_moves <= 0:
			print("WARNING: No more moves!")
	else:
		swap_back(p1, p2)

## Reverts a swap if the move was invalid (created no matches).
func swap_back(p1: Piece, p2: Piece):
	print("Invalid movement - Returning...")
	
	var temp_type = grid_data[p1.grid_x][p1.grid_y]
	grid_data[p1.grid_x][p1.grid_y] = grid_data[p2.grid_x][p2.grid_y]
	grid_data[p2.grid_x][p2.grid_y] = temp_type
	
	var temp_x = p1.grid_x
	var temp_y = p1.grid_y
	p1.grid_x = p2.grid_x
	p1.grid_y = p2.grid_y
	p2.grid_x = temp_x
	p2.grid_y = temp_y
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(p1, "position", p2.position, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(p2, "position", p1.position, 0.3).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	is_processing = false 

## Prints the grid ID layout to the debug console.
func print_grid_to_console():
	print("--- GENERATED MAP ---")
	for y in range(height):
		var row_string = ""
		for x in range(width):
			row_string += str(grid_data[x][y]) + " "
		print(row_string)
	print("---------------------")

## Scans the entire grid for Horizontal and Vertical matches of 3 or more.
## Returns an Array of Vector2 coordinates to be destroyed.
func find_matches() -> Array:
	var matches_found = [] 
	
	for y in height:
		for x in range(width - 2):
			var type1 = grid_data[x][y]
			var type2 = grid_data[x+1][y]
			var type3 = grid_data[x+2][y]
			
			if type1 != null and type1 == type2 and type1 == type3:
				matches_found.append(Vector2(x, y))
				matches_found.append(Vector2(x+1, y))
				matches_found.append(Vector2(x+2, y))
	
	for x in width:
		for y in range(height - 2):
			var type1 = grid_data[x][y]
			var type2 = grid_data[x][y+1]
			var type3 = grid_data[x][y+2]
			
			if type1 != null and type1 == type2 and type1 == type3:
				matches_found.append(Vector2(x, y))
				matches_found.append(Vector2(x, y+1))
				matches_found.append(Vector2(x, y+2))
	
	return matches_found

## Handles the removal of matched pieces and triggers the Combat System.
func destroy_matches(matches: Array):
	var unique_matches = []
	for coord in matches:
		if not unique_matches.has(coord):
			unique_matches.append(coord)
	
	# Batch matches by type to emit grouped signals
	var matches_by_type = {}
	for coord in unique_matches:
		var type_id = grid_data[coord.x][coord.y]
		if not matches_by_type.has(type_id):
			matches_by_type[type_id] = 0
		matches_by_type[type_id] += 1
	
	for type_id in matches_by_type:
		var count = matches_by_type[type_id]
		SignalBus.match_found.emit(type_id, count)
		print("Signal emitted: Type ", type_id, " - Real Amount: ", count)
	
	print("Destroying ", unique_matches.size(), " parts...")
	
	# --- VARIABLES PARA EL CENTROIDE (NUEVO) ---
	var center_sums = {}
	var piece_counts = {}
	# ------------------------------------------
	
	for coord in unique_matches:
		var current_id = grid_data[int(coord.x)][int(coord.y)]
		
		if current_id == null:
			continue
		
		# Limpiamos la data
		grid_data[int(coord.x)][int(coord.y)] = null 
		
		var piece_to_delete = _get_piece_at(int(coord.x), int(coord.y))
		if piece_to_delete:
			# --- ACUMULAMOS POSICIONES PARA EL CENTROIDE (NUEVO) ---
			var screen_pos = piece_to_delete.get_global_transform_with_canvas().origin
			
			if not center_sums.has(current_id):
				center_sums[current_id] = Vector2.ZERO
				piece_counts[current_id] = 0
				
			center_sums[current_id] += screen_pos
			piece_counts[current_id] += 1
			# -------------------------------------------------------
			
			# Animación de desaparición de la gema
			var tween = create_tween()
			tween.tween_property(piece_to_delete, "scale", Vector2.ZERO, 0.2)
			tween.tween_callback(piece_to_delete.queue_free)
	
	for current_id in center_sums:
		var average_pos = center_sums[current_id] / piece_counts[current_id]
		
		SignalBus.vfx_magic_dust_requested.emit(average_pos, int(current_id), is_enemy_turn)
	# -----------------------------------------------------
		
	await get_tree().create_timer(0.3).timeout
	refill_columns() 
	
	await get_tree().create_timer(0.3).timeout 
	print("Destruction complete.")
	is_processing = false

## Returns the Piece node at specific grid coordinates.
func _get_piece_at(target_x: int, target_y: int) -> Piece:
	for child in get_children():
		if child is Piece:
			if child.grid_x == target_x and child.grid_y == target_y:
				return child
	return null

## Handles Gravity and Recursion.
## 1. Moves existing pieces down to fill empty slots (nulls).
## 2. Spawns new pieces above the screen to fill the top.
## 3. Checks for new matches (Chain Reactions) after everything lands.
func refill_columns():
	is_cascading = true
	print("Filling in the board...")
	var tween = create_tween()
	tween.set_parallel(true) 
	
	for x in width:
		var column_pieces = []
		for y in height:
			if grid_data[x][y] != null:
				var p = _get_piece_at(x, y)
				if p: 
					column_pieces.append(p)
		
		var pieces_needed = height - column_pieces.size()
		
		for i in pieces_needed:
			var type = _get_random_piece_type()
			var new_piece = piece_scene.instantiate()
			add_child(new_piece)
			
			var spawn_y_pixel = (y_offset * offset_y) - (offset_y * (pieces_needed - i)) - 50
			var target_x_pixel = x * offset_x + 35
			new_piece.position = Vector2(target_x_pixel, spawn_y_pixel)
			
			new_piece.setup(x, -1, type) 
			new_piece.piece_selected.connect(_on_piece_clicked)
			new_piece.piece_swiped.connect(_on_piece_swiped)
			column_pieces.push_front(new_piece)
			
		for y in height:
			var piece = column_pieces[y]
			grid_data[x][y] = piece.type
			piece.grid_x = x
			piece.grid_y = y
			piece.name = "Piece_" + str(x) + "_" + str(y) 
			
			var target_pos = Vector2(x * offset_x + 35, y * offset_y + 35 + (y_offset * offset_y))
			
			if piece.position != target_pos:
				tween.tween_property(piece, "position", target_pos, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	print("Fall completed.")
	
	# RECURSION: Check for new matches created by the fall
	var new_matches = find_matches()
	if new_matches.size() > 0:
		print("Chain reaction! Destroying again...")
		destroy_matches(new_matches)
	else:
		# Anti-Deadlock implementation
		if not is_move_possible():
			_inject_guaranteed_move()
		
		is_cascading = false 
		is_processing = false
		
		if current_moves > 0:
			print("Board stable. Waiting for input...")
		else:
			print("Board stable AND No moves left -> ENDING TURN NOW.")
			SignalBus.turn_ended.emit()

## Handles swipe input for mobile/touch controls.
func _on_piece_swiped(source_piece: Piece, direction: Vector2):
	if is_game_over or is_enemy_turn or is_processing or is_out_of_lives: return
	if current_moves <= 0: return 
	
	if source_piece.is_locked:
		print("GridManager: Attempted to drag locked piece.")
		return
	
	var target_x = source_piece.grid_x + int(direction.x)
	var target_y = source_piece.grid_y + int(direction.y)
	
	if target_x >= 0 and target_x < width and target_y >= 0 and target_y < height:
		var target_piece = _get_piece_at(target_x, target_y)
		
		if target_piece != null:
			if target_piece.is_locked: 
				print("Target is locked! Cannot swap.")
				return
			
			source_piece.set_selected(false)
			if first_selected:
				first_selected.set_selected(false)
			
			first_selected = null
			second_selected = null
			
			print("Swap by Drag detected: ", source_piece.name, " with ", target_piece.name)
			swap_pieces(source_piece, target_piece)
	else:
		print("Attempt to move off the board")

## Handles the Game Over state.
func _on_game_over(player_won: bool):
	print("GridManager: Input Locked due to Game Over.")
	is_game_over = true

## Handles the transition from the Player Phase to the Enemy Phase.
func _on_player_ended():
	print("GridManager: Player turn ended. Locking grid.")
	is_enemy_turn = true

## Handles the transition from the Enemy Phase back to the Player Phase.
func _on_enemy_finished():
	print("GridManager: Enemy finished. Unlocking grid.")
	is_enemy_turn = false
	reset_turn()

# --- SPECIAL ABILITY FUNCTIONS ---

## Collects (destroys) pieces of a specific type and returns count.
func collect_random_pieces(type_id: int, count: int) -> int:
	var candidates = []
	
	for x in width:
		for y in height:
			if grid_data[x][y] == type_id:
				candidates.append(Vector2(x, y))
	
	candidates.shuffle()
	
	var to_destroy = []
	var collected = 0
	
	for i in range(min(count, candidates.size())):
		to_destroy.append(candidates[i])
		collected += 1
		
	if to_destroy.size() > 0:
		destroy_matches(to_destroy)
		
	return collected

## Converts random pieces (not of target type) into the target type.
func convert_random_pieces_to(target_type_id: int, count: int):
	var candidates = []
	
	for x in width:
		for y in height:
			var current_type = grid_data[x][y]
			if current_type != null and current_type != target_type_id:
				candidates.append(Vector2(x, y))
				
	candidates.shuffle()
	
	for i in range(min(count, candidates.size())):
		var coord = candidates[i]
		var x = int(coord.x)
		var y = int(coord.y)
		
		grid_data[x][y] = target_type_id
		
		var piece_node = _get_piece_at(x, y)
		if piece_node:
			piece_node.setup(x, y, target_type_id)
			
			var tween = create_tween()
			tween.tween_property(piece_node, "scale", Vector2(1.2, 1.2), 0.2)
			tween.tween_property(piece_node, "scale", Vector2(1.0, 1.0), 0.2)
	
	print("GridManager: ", min(count, candidates.size()), " pieces converted to type ", target_type_id)

## Displays dynamic floating text feedback (e.g., Free Moves, Extra Turns).
func _show_floating_text(message: String, text_color: Color):
	var label = Label.new()
	label.text = message
	
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	
	var board_center_x = (width * offset_x) / 2.0
	var board_center_y = (height * offset_y) / 2.0
	label.position = Vector2(board_center_x - 120, board_center_y - 100) 
	label.z_index = 100 
	
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", -100.0, 1.2).as_relative()
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(label.queue_free).set_delay(1.2)

## Scans the board to verify if at least one valid move is possible.
func is_move_possible() -> bool:
	for y in height:
		for x in width:
			if x < width - 1:
				if _simulate_swap_and_check(Vector2(x, y), Vector2(x + 1, y)):
					return true
			if y < height - 1:
				if _simulate_swap_and_check(Vector2(x, y), Vector2(x, y + 1)):
					return true
					
	return false

## Simulates a data swap and checks if it results in a match.
func _simulate_swap_and_check(pos1: Vector2, pos2: Vector2) -> bool:
	var x1 = int(pos1.x)
	var y1 = int(pos1.y)
	var x2 = int(pos2.x)
	var y2 = int(pos2.y)

	var type1 = grid_data[x1][y1]
	var type2 = grid_data[x2][y2]
	if type1 == null or type2 == null: return false
	
	var p1 = _get_piece_at(x1, y1)
	var p2 = _get_piece_at(x2, y2)
	if (p1 and p1.is_locked) or (p2 and p2.is_locked): return false

	grid_data[x1][y1] = type2
	grid_data[x2][y2] = type1
	
	var has_match = find_matches().size() > 0
	
	grid_data[x1][y1] = type1
	grid_data[x2][y2] = type2

	return has_match

## La Mano Invisible: Altera una pieza en silencio para evitar el Deadlock
func _inject_guaranteed_move():
	var types = [0, 1, 2, 3, 4, 5, 6]
	var locked_pieces = [] # <-- Guardamos las piezas bloqueadas por si las necesitamos
	
	# INTENTO 1: Alteración Sutil (El plan original)
	for y in range(height):
		for x in range(width):
			var original_type = grid_data[x][y]
			if original_type == null: continue
			
			var piece = _get_piece_at(x, y)
			
			# Si la pieza está bloqueada, la guardamos para el Plan B y la saltamos
			if piece and piece.is_locked:
				locked_pieces.append(piece)
				continue
			
			if piece == null: continue
			
			types.shuffle() 
			
			for t in types:
				if t == original_type: continue
				
				# 1. Simulamos cambiar esta pieza
				grid_data[x][y] = t
				
				# 2. Verificamos que NO explote sola
				if find_matches().size() == 0:
					# 3. Verificamos si soluciona el tablero
					if is_move_possible():
						piece.setup(x, y, t)
						
						
						var original_scale = piece.sprite.scale 
						
						var tween = create_tween()
						
						tween.tween_property(piece.sprite, "scale", original_scale * 1.2, 0.15)
						
						tween.tween_property(piece.sprite, "scale", original_scale, 0.15)
						# --------------
						
						print("Mano Invisible (Plan A): Pieza en ", x, ",", y, " alterada a tipo ", t)
						return # Solucionado
						
				# Restauramos si no sirvió
				grid_data[x][y] = original_type
	
	# --- INTENTO 2: EL PLAN B (Liberar espacio a la fuerza) ---
	# Si llegamos acá, significa que la Mano Invisible no pudo arreglarlo cambiando colores
	# porque hay demasiadas piezas bloqueadas estorbando.
	
	if locked_pieces.size() > 0:
		print("CRÍTICO: Deadlock irresoluble. Ejecutando Plan B: Romper cadenas.")
		
		# Mezclamos las piezas bloqueadas para romper algunas al azar
		locked_pieces.shuffle()
		
		# Rompemos hasta 3 cadenas para abrir espacio (o menos si hay menos)
		var chains_to_break = min(3, locked_pieces.size())
		
		for i in range(chains_to_break):
			var p = locked_pieces[i]
			p.set_locked(false)
			
			# Efecto visual para que el jugador vea que se rompieron las cadenas
			var tween = create_tween()
			tween.tween_property(p, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BOUNCE)
			tween.tween_property(p, "scale", Vector2(1.0, 1.0), 0.2)
			
		# Una vez que liberamos espacio, volvemos a llamar a la función para que 
		# el Plan A pueda encontrar una solución ahora que hay más libertad.
		_inject_guaranteed_move()

## AI SCANNER: Searches for and returns the first valid move it finds on the grid.
## Returns an array with the two Vector2 positions to swap, or empty if there is a deadlock.
func get_ai_valid_move() -> Array:
	var possible_moves = []
	
	for y in height:
		for x in width:
			if x < width - 1:
				if _simulate_swap_and_check(Vector2(x, y), Vector2(x + 1, y)):
					possible_moves.append([Vector2(x, y), Vector2(x + 1, y)])
			
			
			if y < height - 1:
				if _simulate_swap_and_check(Vector2(x, y), Vector2(x, y + 1)):
					possible_moves.append([Vector2(x, y), Vector2(x, y + 1)])
					
	if possible_moves.size() > 0:
		
		possible_moves.shuffle()
		return possible_moves[0]
		
	return [] 

## AI HAND: Physically executes the movement on the board simulating a human.
func execute_ai_move(pos1: Vector2, pos2: Vector2):
	is_processing = true 
	
	var p1 = _get_piece_at(int(pos1.x), int(pos1.y))
	var p2 = _get_piece_at(int(pos2.x), int(pos2.y))
	
	if p1 and p2:
		
		p1.modulate = Color(1.2, 1.2, 1.2)
		p1.scale = Vector2(1.1, 1.1)
		print("IA: Seleccionó la pieza en ", pos1)
		
		await get_tree().create_timer(0.6).timeout
		
		
		p1.modulate = Color.WHITE
		p1.scale = Vector2(1.0, 1.0)
		print("IA: Intercambiando con ", pos2)
		
		swap_pieces(p1, p2)
	else:
		is_processing = false 

## Generates a piece type based on probabilities (Weight System).
## High probability (3/17): Gems (0, 1, 2), Bombs (3), Steering Wheels (4).
# Low probability (1/17): Gold (5), XP (6).
func _get_random_piece_type() -> int:
	var spawn_pool = [
		0, 0, 0, # Red 
		1, 1, 1, # Blue 
		2, 2, 2, # Green 
		3, 3, 3, # Bomb 
		4, 4, 4, # Helm 
		5,       # Gold 
		6        # XP 
	]
	return spawn_pool[randi() % spawn_pool.size()]
