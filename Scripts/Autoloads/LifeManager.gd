extends Node

const MAX_LIVES = 5
const RECHARGE_TIME = 1800 # 30 min
const SAVE_PATH = "user://meta_save.json"

# --- VARIABLES ---
var current_lives: int = MAX_LIVES
var poseidon_fragments: int = 50 
var time_left_for_next_life: int = RECHARGE_TIME

func _ready():
	load_game()
	
	# --- RESET MANUAL RÁPIDO ---
	# Si alguna vez quieres resetear todo a cero mientras pruebas:
	# Descomenta las 3 líneas de abajo, dale a PLAY una vez, y vuelve a comentarlas.
	#current_lives = MAX_LIVES
	#poseidon_fragments = 50
	#save_game()

	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)

func _on_timer_tick():
	if current_lives < MAX_LIVES:
		time_left_for_next_life -= 1
		if time_left_for_next_life <= 0:
			current_lives += 1
			time_left_for_next_life = RECHARGE_TIME
			save_game() # Guardamos la vida recuperada
		SignalBus.life_system_updated.emit(current_lives, time_left_for_next_life)
	else:
		# Si estamos al máximo, enviamos RECHARGE_TIME para que la UI sepa que no hay descuento
		SignalBus.life_system_updated.emit(current_lives, RECHARGE_TIME)

func can_play() -> bool:
	return current_lives > 0

func consume_life_to_play() -> bool:
	if current_lives > 0:
		current_lives -= 1
		save_game()
		# --- EL FIX: Avisar a la UI que ahora hay una vida menos ---
		SignalBus.life_system_updated.emit(current_lives, time_left_for_next_life)
		return true
	return false

func buy_lives_with_fragments(amount_to_buy: int, cost: int):
	if poseidon_fragments >= cost:
		poseidon_fragments -= cost
		current_lives = min(current_lives + amount_to_buy, MAX_LIVES)
		save_game()
		SignalBus.poseidon_fragments_changed.emit(poseidon_fragments)
		return true
	return false

func save_game():
	var data = {
		"lives": current_lives,
		"fragments": poseidon_fragments,
		"time_left": time_left_for_next_life,
		"exit_time": Time.get_unix_time_from_system()
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data:
			current_lives = int(data.get("lives", MAX_LIVES))
			poseidon_fragments = int(data.get("fragments", 50))
			_calculate_offline_progress(data.get("time_left", RECHARGE_TIME), data.get("exit_time", 0))

func _calculate_offline_progress(saved_time, exit_time):
	if exit_time == 0 or current_lives >= MAX_LIVES: return
	var s_time = int(saved_time)
	var elapsed = int(Time.get_unix_time_from_system() - exit_time)
	if elapsed >= s_time:
		current_lives += 1
		elapsed -= s_time
		var extra = int(elapsed / RECHARGE_TIME)
		current_lives = min(current_lives + extra, MAX_LIVES)
		time_left_for_next_life = RECHARGE_TIME - (elapsed % RECHARGE_TIME)
	else:
		time_left_for_next_life = s_time - elapsed

# --- DEBUG/TESTING CHEAT ---
## Restaura las vidas y los fragmentos al máximo. Usar solo para testing.
func cheat_max_resources():
	current_lives = MAX_LIVES
	poseidon_fragments += 1000 # Le damos suficientes para testear la tienda
	time_left_for_next_life = RECHARGE_TIME
	save_game()
	
	# Emitimos señales para que la UI se actualice al instante
	SignalBus.life_system_updated.emit(current_lives, time_left_for_next_life)
	SignalBus.poseidon_fragments_changed.emit(poseidon_fragments)
	print("CHEAT ACTIVADO: Vidas y Fragmentos al máximo.")
