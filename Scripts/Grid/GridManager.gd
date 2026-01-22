extends Node2D

## Core system that manages the Match-3 grid logic.
## Handles procedural generation, input state machine, swapping mechanics, 
## match detection algorithms, and the refill cascade (gravity).
class_name GridManager

# --- CONFIGURATION ---
@export var width: int = 7
@export var height: int = 9
@export var offset: int = 70 
@export var y_offset: int = 2 
@export var piece_scene: PackedScene

# --- DATA ---
# 2D Array storing the logical state of the grid (Integers representing IDs).
var grid_data: Array = [] 

# --- STATE MANAGEMENT ---
var first_selected: Piece = null
var second_selected: Piece = null
var is_processing: bool = false 

func _ready():
	randomize() 
	
	grid_data = make_2d_array()
	spawn_pieces()
	
	print_grid_to_console()

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
			var possible_type = randi() % 4
			while _match_is_possible(x, y, possible_type):
				possible_type = randi() % 4
			
			grid_data[x][y] = possible_type
			
			
			var piece = piece_scene.instantiate()
			add_child(piece)
			
			var pixel_x = x * offset + 35
			var pixel_y = y * offset + 35 + (y_offset * offset)
			piece.position = Vector2(pixel_x, pixel_y)
			
			piece.setup(x, y, possible_type)
			
			if not piece.piece_selected.is_connected(_on_piece_clicked):
				piece.piece_selected.connect(_on_piece_clicked)

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
func _on_piece_clicked(piece: Piece):
	if is_processing: return 
	
	if first_selected == null:
		first_selected = piece
		first_selected.modulate = Color(1.2, 1.2, 1.2) 
		print("Seleccionada 1: ", piece.grid_x, ",", piece.grid_y)
		
	elif first_selected == piece:
		first_selected.modulate = Color.WHITE
		first_selected = null
		print("Deseleccionada")
		
	else:
		second_selected = piece
		print("Seleccionada 2: ", piece.grid_x, ",", piece.grid_y)
		
		if _is_adjacent(first_selected, second_selected):
			first_selected.modulate = Color.WHITE
			swap_pieces(first_selected, second_selected)
		else:
			first_selected.modulate = Color.WHITE
			first_selected = piece
			first_selected.modulate = Color(1.2, 1.2, 1.2)
			second_selected = null

## Checks if two pieces are immediate neighbors (Horizontally or Vertically).
func _is_adjacent(p1: Piece, p2: Piece) -> bool:
	var diff_x = abs(p1.grid_x - p2.grid_x)
	var diff_y = abs(p1.grid_y - p2.grid_y)
	return (diff_x + diff_y) == 1

## Core Mechanic: Swaps two pieces in Data and Visually.
## If no match is found after the swap, it triggers 'swap_back'.
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
	
	# 4. Validate Move
	var matches = find_matches()
	
	if matches.size() > 0:
		destroy_matches(matches)
	else:
		swap_back(p1, p2)
	
	first_selected = null
	second_selected = null

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
## 1. Emits 'match_found' signal for the CombatManager.
## 2. Removes visual nodes and clears data.
## 3. Calls 'refill_columns' to start the cascade.
func destroy_matches(matches: Array):
	# --- COMBAT HOOK ---
	if matches.size() > 0:
		
		var first_coord = matches[0]
		var type_id = grid_data[first_coord.x][first_coord.y]
		var count = matches.size()
		
		SignalBus.match_found.emit(type_id, count)
		print("Señal emitida: Tipo ", type_id, " - Cantidad: ", count)	
	
	print("Destruyendo ", matches.size(), " piezas...")
	for coord in matches:
		if grid_data[coord.x][coord.y] == null:
			continue
			
		grid_data[coord.x][coord.y] = null 
		
		var piece_to_delete = _get_piece_at(coord.x, coord.y)
		if piece_to_delete:
			var tween = create_tween()
			tween.tween_property(piece_to_delete, "scale", Vector2.ZERO, 0.2)
			tween.tween_callback(piece_to_delete.queue_free) 
	
	await get_tree().create_timer(0.3).timeout
	
	refill_columns() 
	
	await get_tree().create_timer(0.3).timeout 
	print("Destrucción terminada.")
	is_processing = false 


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
	print("Rellenando tablero...")
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
			var type = randi() % 4
			var new_piece = piece_scene.instantiate()
			add_child(new_piece)
			
			var spawn_y_pixel = (y_offset * offset) - (offset * (pieces_needed - i)) - 50
			var target_x_pixel = x * offset + 35
			new_piece.position = Vector2(target_x_pixel, spawn_y_pixel)
			
			new_piece.setup(x, -1, type) 
			new_piece.piece_selected.connect(_on_piece_clicked)
			
			column_pieces.push_front(new_piece)
			
		for y in height:
			var piece = column_pieces[y]
			
			grid_data[x][y] = piece.type
			
			piece.grid_x = x
			piece.grid_y = y
			piece.name = "Piece_" + str(x) + "_" + str(y) 
			
			var target_pos = Vector2(x * offset + 35, y * offset + 35 + (y_offset * offset))
			
			if piece.position != target_pos:
				tween.tween_property(piece, "position", target_pos, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	print("Caída terminada.")
	
	# RECURSION: Check for new matches created by the fall
	var new_matches = find_matches()
	if new_matches.size() > 0:
		print("¡Reacción en cadena! Destruyendo de nuevo...")
		destroy_matches(new_matches)
	else:
		is_processing = false
		print("Turno finalizado. Jugador puede mover.")
