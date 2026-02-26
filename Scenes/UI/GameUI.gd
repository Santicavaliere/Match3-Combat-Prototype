extends CanvasLayer

@export_group("Health Bars")
@export var hp_bar_player: TextureProgressBar
@export var hp_bar_enemy: TextureProgressBar

@export_group("Helm Bars (Evasion)")
@export var helm_bar_player: TextureProgressBar
@export var helm_bar_enemy: TextureProgressBar

@export_group("Player Mana Bars (Left)")
@export var player_mana_red: TextureProgressBar
@export var player_mana_blue: TextureProgressBar
@export var player_mana_green: TextureProgressBar

@export_group("Enemy Mana Bars (Right)")
@export var enemy_mana_red: TextureProgressBar
@export var enemy_mana_blue: TextureProgressBar
@export var enemy_mana_green: TextureProgressBar

@export_group("Textos")
@export var turn_text: Label

@export_group("Efectos Visuales")
@export var magic_overlay: TextureRect

@export_group("Magias Equipadas (Golden Scroll)")
@export var equipped_abilities: Array[Ability]
@export var magic_buttons: Array[TextureRect] # Antes decía TextureButton

func _ready():
	# --- CONEXIÓN DE SEÑALES ---
	SignalBus.player_hp_changed.connect(_update_player_hp)
	SignalBus.enemy_hp_changed.connect(_update_enemy_hp)
	SignalBus.mana_updated.connect(_update_mana)
	SignalBus.moves_updated.connect(_update_moves)
	
	SignalBus.player_evasion_changed.connect(_update_player_helm)
	SignalBus.enemy_evasion_changed.connect(_update_enemy_helm)
	# --- NUEVO: Conectamos la animación épica ---
	SignalBus.ability_cast_success.connect(_on_ability_cast_success)
	
	# --- FIX VISUAL INICIAL ---
	if hp_bar_player: hp_bar_player.value = hp_bar_player.max_value
	if hp_bar_enemy: hp_bar_enemy.value = hp_bar_enemy.max_value
	if helm_bar_player: helm_bar_player.value = 0
	if helm_bar_enemy: helm_bar_enemy.value = 0
	
	# Nos aseguramos de que las barras del enemigo empiecen en 0
	if enemy_mana_red: enemy_mana_red.value = 0
	if enemy_mana_blue: enemy_mana_blue.value = 0
	if enemy_mana_green: enemy_mana_green.value = 0
	
	# --- PREPARAR CARTAS DEL PERGAMINO ---
	# Ocultamos el contenedor y hacemos transparentes a los hijos
	$HorizontalScroll/HBoxContainer.hide()
	for carta in $HorizontalScroll/HBoxContainer.get_children():
		carta.modulate.a = 0.0
	
	_setup_magic_panel()

# --- FUNCIONES QUE RECIBEN LA SEÑAL ---

func _update_player_hp(current, max_val):
	hp_bar_player.max_value = max_val
	_animate_bar(hp_bar_player, current)

func _update_enemy_hp(current, max_val):
	hp_bar_enemy.max_value = max_val
	_animate_bar(hp_bar_enemy, current)

func _update_player_helm(current_evasion):
	# La evasión va de 0.0 a 0.9. Lo multiplicamos por 100 para la barra.
	_animate_bar(helm_bar_player, int(current_evasion * 100))

func _update_enemy_helm(current_evasion):
	_animate_bar(helm_bar_enemy, int(current_evasion * 100))

func _update_mana(pool: Dictionary):
	# CORRECCIÓN: Ahora usa las variables con el prefijo "player_"
	_animate_bar(player_mana_red, pool["red"])
	_animate_bar(player_mana_blue, pool["blue"])
	_animate_bar(player_mana_green, pool["green"])

func _update_moves(amount):
	if turn_text:
		turn_text.text = str(amount) # Solo mandamos el número para el espejo

# --- MAGIA VISUAL (TWEENS) ---
func _animate_bar(bar: TextureProgressBar, new_value: float): # <--- Cambiado a float
	if bar == null: return
	
	var tween = create_tween()
	# Forzamos que sea float para que el Tween no tenga errores de tipo
	tween.tween_property(bar, "value", float(new_value), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_horizontal_scroll_animation_finished() -> void:
	# 1. Hacemos visible el contenedor (las cartas siguen invisibles por el alpha 0)
	$HorizontalScroll/HBoxContainer.show()
	
	# 2. Creamos el animador
	var tween = create_tween()
	
	# 3. Magia de Godot: Al ponerlas en un mismo "for" con un solo Tween, 
	# Godot automáticamente las anima una DESPUÉS de la otra (Cascada)
	for carta in $HorizontalScroll/HBoxContainer.get_children():
		tween.tween_property(carta, "modulate:a", 1.0, 0.15)

func _setup_magic_panel():
	for i in range(magic_buttons.size()):
		var slot = magic_buttons[i]
		
		if i < equipped_abilities.size() and equipped_abilities[i] != null:
			var ability = equipped_abilities[i]
			
			# 1. Buscamos el BOTÓN hijo (Acordate de renombrarlos TODOS a "IconBtn" en la escena)
			var icon_btn = slot.get_node_or_null("IconBtn")
			if icon_btn and ability.icon_magic:
				icon_btn.texture_normal = ability.icon_magic
				
				# --- EL TRUCO DEFINITIVO DE TAMAÑO Y CENTRADO ---
				icon_btn.ignore_texture_size = true
				icon_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				
				# Le decimos que ocupe todo el espacio del cuadrado marrón
				icon_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
				
				# Conectamos el clic SOLAMENTE al ícono
				for conn in icon_btn.pressed.get_connections():
					icon_btn.pressed.disconnect(conn.callable)
				icon_btn.pressed.connect(func(): SignalBus.ability_cast_requested.emit(ability))
				
			# 2. Las cajas de costo (Corregido el orden visual)
			var box_red = slot.get_node_or_null("BoxRed")
			
			# Como "BoxBlue" está físicamente en el medio, lo usamos para el costo verde
			var box_green = slot.get_node_or_null("BoxBlue") 
			
			# Como "BoxGreen" está físicamente a la derecha, lo usamos para el costo azul
			var box_blue = slot.get_node_or_null("BoxGreen")
			
			if box_red:
				box_red.visible = (ability.cost_red > 0)
				if box_red.has_node("Label"): box_red.get_node("Label").text = str(ability.cost_red)
				
			if box_blue:
				box_blue.visible = (ability.cost_blue > 0)
				if box_blue.has_node("Label"): box_blue.get_node("Label").text = str(ability.cost_blue)
				
			if box_green:
				box_green.visible = (ability.cost_green > 0)
				if box_green.has_node("Label"): box_green.get_node("Label").text = str(ability.cost_green)
# Variable para guardar la animación actual y evitar que se pisen
var overlay_tween: Tween

# --- ANIMACIÓN CENTRAL DE MAGIA ---
func _on_ability_cast_success(ability: Ability):
	if magic_overlay and ability.icon_magic:
		if overlay_tween and overlay_tween.is_running():
			overlay_tween.kill()
		
		# Preparamos la imagen
		magic_overlay.texture = ability.icon_magic
		magic_overlay.show()
		
		# Centramos el pivote para que crezca desde el medio
		magic_overlay.pivot_offset = magic_overlay.size / 2
		
		# Estado inicial transparente y a la mitad de su tamaño
		magic_overlay.modulate.a = 0.0
		magic_overlay.scale = Vector2(0.1, 0.1)
		
		overlay_tween = create_tween()
		
		# Fase 1: Aparece y crece hasta la mitad de su tamaño (50%) o menos.
		# Probá con 0.5 o 0.4 si lo querés aún más chico.
		overlay_tween.set_parallel(true)
		overlay_tween.tween_property(magic_overlay, "modulate:a", 1.0, 0.3)
		overlay_tween.tween_property(magic_overlay, "scale", Vector2(0.4, 0.4), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Fase 2: Se queda quieto 1 segundo completo, luego se desvanece suavemente en medio segundo
		overlay_tween.set_parallel(false)
		overlay_tween.tween_property(magic_overlay, "modulate:a", 0.0, 0.5).set_delay(1.0)
		
		# Fase 3: Se oculta
		overlay_tween.tween_callback(magic_overlay.hide)
