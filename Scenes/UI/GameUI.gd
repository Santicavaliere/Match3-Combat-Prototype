extends CanvasLayer

# --- REFERENCIAS VISUALES (Las llenaremos en el Inspector) ---
@export_group("Health Bars")
@export var hp_bar_player: TextureProgressBar
@export var hp_bar_enemy: TextureProgressBar

@export_group("Mana Bars")
@export var mana_red: TextureProgressBar
@export var mana_blue: TextureProgressBar
@export var mana_green: TextureProgressBar

@export_group("Textos")
@export var moves_label: Label # Opcional por ahora

func _ready():
	# --- CONEXIÓN DE SEÑALES ---
	# Escuchamos al SignalBus. Cuando el CombatManager grite, nosotros actualizamos.
	SignalBus.player_hp_changed.connect(_update_player_hp)
	SignalBus.enemy_hp_changed.connect(_update_enemy_hp)
	SignalBus.mana_updated.connect(_update_mana)
	SignalBus.moves_updated.connect(_update_moves)
	
	# --- FIX VISUAL INICIAL ---
	# Aseguramos que visualmente empiecen llenas para evitar el "salto"
	# si el CombatManager tarda en enviar la info.
	if hp_bar_player: 
		hp_bar_player.value = hp_bar_player.max_value
	if hp_bar_enemy: 
		hp_bar_enemy.value = hp_bar_enemy.max_value

# --- FUNCIONES QUE RECIBEN LA SEÑAL ---

func _update_player_hp(current, max_val):
	# Asignamos el máximo por si cambió
	hp_bar_player.max_value = max_val
	# Animamos la barra suavemente
	_animate_bar(hp_bar_player, current)

func _update_enemy_hp(current, max_val):
	hp_bar_enemy.max_value = max_val
	_animate_bar(hp_bar_enemy, current)

func _update_mana(pool: Dictionary):
	# Actualizamos las 3 barras de golpe
	_animate_bar(mana_red, pool["red"])
	_animate_bar(mana_blue, pool["blue"])
	_animate_bar(mana_green, pool["green"])

func _update_moves(amount):
	if moves_label:
		moves_label.text = "Moves: %d" % amount

# --- MAGIA VISUAL (TWEENS) ---
# Esta función hace que la barra baje suave en 0.4 segundos
func _animate_bar(bar: TextureProgressBar, new_value: int):
	if bar == null: return # Seguridad
	
	var tween = create_tween()
	tween.tween_property(bar, "value", new_value, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
