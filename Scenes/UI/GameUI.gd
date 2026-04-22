extends CanvasLayer

## Global User Interface Manager.
## Handles the visual representation of combat stats, resources, abilities, and end-match screens.
@export var magic_dust_scene: PackedScene

@export_group("Anclas Visuales VFX")
@export var target_mana_red: Marker2D
@export var target_mana_blue: Marker2D
@export var target_mana_green: Marker2D
@export var target_gold: Marker2D
@export var target_xp: Marker2D

@export_group("Anclas Visuales VFX Enemigo")
@export var target_enemy_mana_red: Marker2D
@export var target_enemy_mana_blue: Marker2D
@export var target_enemy_mana_green: Marker2D
@export var target_enemy_gold: Marker2D
@export var target_enemy_xp: Marker2D

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

@export_group("Recursos (Oro y XP)")
@export var gold_label: Label
@export var xp_label: Label
@export var enemy_gold_label: Label 
@export var enemy_xp_label: Label   

@export_group("Textos")
@export var turn_text: Label

@export_group("Premium System (Vidas)")
@export var lives_label: Label
@export var timer_label: Label
@export var fragments_label: Label
@export var lives_bar: TextureProgressBar
@export var lives_purchase_popup: Control
@export var btn_buy_lives: Button
@export var btn_close_popup: Button

@export_group("Efectos Visuales")
@export var magic_overlay: TextureRect

@export_group("Magias Equipadas (Golden Scroll)")
@export var equipped_abilities: Array[Ability]
@export var magic_buttons: Array[TextureRect]
var lock_overlays: Array[TextureRect] = []
const LOCK_ICON = preload("res://Assets/Final/UI/candado bloqueo de magia.png") # <-- Reemplazar con tu ruta

@export_group("Magias Equipadas Enemigo")
@export var enemy_equipped_abilities: Array[Ability]
@export var enemy_magic_buttons: Array[TextureRect] # O la clase base que uses
var enemy_lock_overlays: Array[TextureRect] = []

@export_group("End Match Screens")
@export var tex_you_win: Texture2D
@export var tex_game_over: Texture2D

@onready var game_over_panel = $GameOverPanel
@onready var result_image = $GameOverPanel/ResultImage

@onready var pause_menu_panel = $PauseMenuPanel
@onready var btn_resume = $PauseMenuPanel/VBoxContainer/BtnResume
@onready var btn_main_menu = $PauseMenuPanel/VBoxContainer/BtnMainMenu

@onready var gold_result_label = $GameOverPanel.find_child("GoldResultLabel", true, false)
@onready var xp_result_label = $GameOverPanel.find_child("XPResultLabel", true, false)
@onready var winner_loadout_container = $GameOverPanel.find_child("WinnerLoadoutContainer", true, false)
@onready var most_used_card = $GameOverPanel.find_child("MostUsedCard", true, false)
@onready var btn_reload = $GameOverPanel.find_child("BtnReload", true, false)
@onready var btn_next = $GameOverPanel.find_child("BtnNext", true, false)

var match_gold: int = 0
var match_xp: int = 0
var ability_usage_count: Dictionary = {}
var overlay_tween: Tween

## Initializes the UI state, connects to the global SignalBus, and prepares visual elements.
func _ready():
	# --- SIGNAL CONNECTIONS ---
	SignalBus.player_hp_changed.connect(_update_player_hp)
	SignalBus.enemy_hp_changed.connect(_update_enemy_hp)
	SignalBus.mana_updated.connect(_update_mana)
	SignalBus.moves_updated.connect(_update_moves)
	
	SignalBus.player_evasion_changed.connect(_update_player_helm)
	SignalBus.enemy_evasion_changed.connect(_update_enemy_helm)
	
	SignalBus.ability_cast_success.connect(_on_ability_cast_success)
	SignalBus.player_gold_changed.connect(_update_gold)
	SignalBus.player_xp_changed.connect(_update_xp)
	
	SignalBus.vfx_magic_dust_requested.connect(_spawn_magic_dust)
	
	SignalBus.enemy_gold_changed.connect(_update_enemy_gold)
	SignalBus.enemy_xp_changed.connect(_update_enemy_xp)
	SignalBus.enemy_mana_updated.connect(_update_enemy_mana)
	SignalBus.game_over.connect(_on_game_over)
	
	
	SignalBus.life_system_updated.connect(_update_lives_hud)
	SignalBus.poseidon_fragments_changed.connect(_update_fragments_hud)
	SignalBus.show_lives_purchase_popup.connect(_show_lives_popup)
	
	
	if btn_buy_lives: 
		btn_buy_lives.pressed.connect(_on_buy_lives_pressed)
	if btn_close_popup: 
		btn_close_popup.pressed.connect(func(): lives_purchase_popup.hide())
		
	if lives_purchase_popup: 
		lives_purchase_popup.hide()
		
	
	_update_fragments_hud(LifeManager.poseidon_fragments)
	
	# --- INITIAL STATE SETUP ---
	if game_over_panel:
		game_over_panel.hide()
	
	if hp_bar_player: hp_bar_player.value = hp_bar_player.max_value
	if hp_bar_enemy: hp_bar_enemy.value = hp_bar_enemy.max_value
	if helm_bar_player: helm_bar_player.value = 0
	if helm_bar_enemy: helm_bar_enemy.value = 0
	
	if enemy_mana_red: enemy_mana_red.value = 0
	if enemy_mana_blue: enemy_mana_blue.value = 0
	if enemy_mana_green: enemy_mana_green.value = 0
	
	$HorizontalScroll/HBoxContainer.hide()
	for carta in $HorizontalScroll/HBoxContainer.get_children():
		carta.modulate.a = 0.0
	
	# --- HIDE ENEMY SCROLL AT START ---
	if has_node("HorizontalScrollEnemy/HBoxContainer"):
		$HorizontalScrollEnemy/HBoxContainer.hide()
		for carta_enemigo in $HorizontalScrollEnemy/HBoxContainer.get_children():
			carta_enemigo.modulate.a = 0.0
			
	# --- PAUSE MENU SETUP ---
	if pause_menu_panel:
		pause_menu_panel.hide()
		
	if btn_resume:
		btn_resume.pressed.connect(_resume_game)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_go_to_main_menu)
	
	if btn_reload: 
		btn_reload.pressed.connect(_on_reload_pressed)
		# FIX: Achicamos a 0.85 cuando presiona, volvemos a 1.0 cuando suelta
		btn_reload.button_down.connect(func(): btn_reload.scale = Vector2(0.85, 0.85))
		btn_reload.button_up.connect(func(): btn_reload.scale = Vector2(1.0, 1.0))
		
	if btn_next: 
		btn_next.pressed.connect(_on_next_pressed)
		# FIX: Achicamos a 0.85 cuando presiona, volvemos a 1.0 cuando suelta
		btn_next.button_down.connect(func(): btn_next.scale = Vector2(0.85, 0.85))
		btn_next.button_up.connect(func(): btn_next.scale = Vector2(1.0, 1.0))
	
	_setup_magic_panel()
	_setup_enemy_magic_panel()
	
	_update_enemy_locked_skills({"red": 0, "blue": 0, "green": 0})
	_update_lives_hud(LifeManager.current_lives, LifeManager.time_left_for_next_life)
	_update_fragments_hud(LifeManager.poseidon_fragments)

# --- SIGNAL RECEIVERS ---

func _update_player_hp(current, max_val):
	hp_bar_player.max_value = max_val
	_animate_bar(hp_bar_player, current)

func _update_enemy_hp(current, max_val):
	hp_bar_enemy.max_value = max_val
	_animate_bar(hp_bar_enemy, current)

func _update_player_helm(current_evasion):
	# Evasion ranges from 0.0 to 0.9. Multiply by 100 for the UI progress bar.
	_animate_bar(helm_bar_player, int(current_evasion * 100))

func _update_enemy_helm(current_evasion):
	_animate_bar(helm_bar_enemy, int(current_evasion * 100))

func _update_mana(pool: Dictionary):
	_animate_bar(player_mana_red, pool["red"])
	_animate_bar(player_mana_blue, pool["blue"])
	_animate_bar(player_mana_green, pool["green"])
	_update_locked_skills(pool)

func _update_enemy_mana(pool: Dictionary):
	_animate_bar(enemy_mana_red, pool["red"])
	_animate_bar(enemy_mana_blue, pool["blue"])
	_animate_bar(enemy_mana_green, pool["green"])
	_update_enemy_locked_skills(pool) 

func _update_moves(amount):
	if turn_text:
		turn_text.text = str(amount)

func _update_gold(amount: int):
	match_gold = amount # Guardamos el progreso de la partida
	if gold_label:
		gold_label.text = str(amount)

func _update_enemy_gold(amount: int):
	if enemy_gold_label:
		enemy_gold_label.text = str(amount)

func _update_enemy_xp(amount: int):
	if enemy_xp_label:
		enemy_xp_label.text = str(amount)

func _update_xp(amount: int):
	match_xp = amount # Guardamos el progreso de la partida
	if xp_label:
		xp_label.text = str(amount)

# --- VISUAL MAGIC (TWEENS) ---

## Smoothly animates a TextureProgressBar to a new value.
func _animate_bar(bar: TextureProgressBar, new_value: float):
	if bar == null: return
	
	var tween = create_tween()
	tween.tween_property(bar, "value", float(new_value), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Triggers a cascading fade-in animation for the equipped scroll cards.
func _on_horizontal_scroll_animation_finished() -> void:
	# --- ANIMATE PLAYER SCROLL (CASCADING) ---
	$HorizontalScroll/HBoxContainer.show()
	var tween_player = create_tween()
	
	for carta in $HorizontalScroll/HBoxContainer.get_children():
		tween_player.tween_property(carta, "modulate:a", 1.0, 0.15)
		
	# --- ANIMATE ENEMY SCROLL (CASCADING) ---
	if has_node("HorizontalScrollEnemy/HBoxContainer"):
		$HorizontalScrollEnemy/HBoxContainer.show()
		var tween_enemy = create_tween()
		
		for carta_enemigo in $HorizontalScrollEnemy/HBoxContainer.get_children():
			tween_enemy.tween_property(carta_enemigo, "modulate:a", 1.0, 0.15)

## Dynamically configures the UI buttons and cost labels for the equipped abilities.
func _setup_magic_panel():
	for i in range(magic_buttons.size()):
		var slot = magic_buttons[i]
		
		if i < equipped_abilities.size() and equipped_abilities[i] != null:
			var ability = equipped_abilities[i]
			
			var icon_btn = slot.get_node_or_null("IconBtn")
			if icon_btn and ability.icon_magic:
				icon_btn.texture_normal = ability.icon_magic
				icon_btn.ignore_texture_size = true
				icon_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				icon_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
				
				for conn in icon_btn.pressed.get_connections():
					icon_btn.pressed.disconnect(conn.callable)
				icon_btn.pressed.connect(func(): SignalBus.ability_cast_requested.emit(ability))
				
				# --- CREACIÓN DEL CANDADO POR CÓDIGO ---
				var lock = TextureRect.new()
				lock.texture = LOCK_ICON
				lock.ignore_texture_size = true
				lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				lock.set_anchors_preset(Control.PRESET_FULL_RECT)
				lock.mouse_filter = Control.MOUSE_FILTER_IGNORE # Para que no bloquee el click
				lock.hide() 
				
				slot.add_child(lock)
				lock_overlays.append(lock)
				# ---------------------------------------
			
			var box_red = slot.get_node_or_null("BoxRed")
			var box_green = slot.get_node_or_null("BoxBlue") 
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

# --- CENTRAL MAGIC ANIMATION ---

## Plays the central screen overlay animation when a magic ability is successfully cast.
func _on_ability_cast_success(ability: Ability):
	if not ability_usage_count.has(ability):
		ability_usage_count[ability] = 0
	ability_usage_count[ability] += 1
	
	if magic_overlay and ability.icon_magic:
		if overlay_tween and overlay_tween.is_running():
			overlay_tween.kill()
		
		magic_overlay.texture = ability.icon_magic
		magic_overlay.show()
		
		var target_pixel_size = 500.0 
		
		
		var tex_size = ability.icon_magic.get_size()
		var max_side = max(tex_size.x, tex_size.y)
		var final_scale = target_pixel_size / max_side
		
		
		magic_overlay.pivot_offset = magic_overlay.size / 2.0
		
		magic_overlay.modulate.a = 0.0
		
		magic_overlay.scale = Vector2(final_scale * 0.2, final_scale * 0.2)
		
		overlay_tween = create_tween()
		
		overlay_tween.set_parallel(true)
		overlay_tween.tween_property(magic_overlay, "modulate:a", 1.0, 0.3)
		
		overlay_tween.tween_property(magic_overlay, "scale", Vector2(final_scale, final_scale), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		overlay_tween.set_parallel(false)
		overlay_tween.tween_property(magic_overlay, "modulate:a", 0.0, 0.5).set_delay(1.0)
		
		overlay_tween.tween_callback(magic_overlay.hide)

# --- END GAME SCREENS ---

func _on_game_over(player_won: bool):
	if not game_over_panel or not result_image: return
	
	result_image.texture = tex_you_win if player_won else tex_game_over
	
	if player_won:
		# 1. Asignar los valores guardados durante la partida
		if gold_result_label: gold_result_label.text = str(match_gold)
		if xp_result_label: xp_result_label.text = str(match_xp)
			
		# 2. Calcular la carta más usada
		var best_ability: Ability = null
		var max_uses: int = 0
		
		for ability in ability_usage_count:
			if ability_usage_count[ability] > max_uses:
				max_uses = ability_usage_count[ability]
				best_ability = ability
				
		# Mostrar la carta ganadora (o la primera equipada si ganó sin usar magias)
		if most_used_card:
			if best_ability != null and best_ability.icon_talisman != null:
				most_used_card.texture = best_ability.icon_talisman
			elif equipped_abilities.size() > 0 and equipped_abilities[0] != null:
				most_used_card.texture = equipped_abilities[0].icon_talisman
				
		# 3. Generar el mazo visual (Winner Loadout)
		if winner_loadout_container:
			var placeholder_cards = winner_loadout_container.get_children()
			for i in range(placeholder_cards.size()):
				var card_node = placeholder_cards[i]
				
				if i < equipped_abilities.size() and equipped_abilities[i] != null and equipped_abilities[i].icon_talisman != null:
					card_node.texture = equipped_abilities[i].icon_talisman
					card_node.show() 
				else:
					card_node.hide()
						
	# Mostrar el panel con el efecto de Fade
	game_over_panel.modulate.a = 0.0
	game_over_panel.show()
	var tween = create_tween()
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)

func _update_locked_skills(pool: Dictionary):
	for i in range(equipped_abilities.size()):
		if i >= lock_overlays.size() or lock_overlays[i] == null or equipped_abilities[i] == null:
			continue
			
		var ability = equipped_abilities[i]
		var lock = lock_overlays[i]
		var btn = magic_buttons[i]
		
		# Verificamos si alcanza el maná
		if pool.get("red", 0) < ability.cost_red or \
		   pool.get("blue", 0) < ability.cost_blue or \
		   pool.get("green", 0) < ability.cost_green:
			lock.show()
			if btn: btn.modulate = Color(0.5, 0.5, 0.5) # Oscurece el botón
		else:
			lock.hide()
			if btn: btn.modulate = Color.WHITE # Lo vuelve normal

## Dynamically configures the UI buttons and cost labels for the ENEMY'S equipped abilities.
func _setup_enemy_magic_panel():
	for i in range(enemy_magic_buttons.size()):
		var slot = enemy_magic_buttons[i]
		
		if i < enemy_equipped_abilities.size() and enemy_equipped_abilities[i] != null:
			var ability = enemy_equipped_abilities[i]
			
			var icon_btn = slot.get_node_or_null("IconBtn")
			if icon_btn and ability.icon_magic:
				icon_btn.texture_normal = ability.icon_magic
				icon_btn.ignore_texture_size = true
				icon_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				icon_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
				
				# Desactivamos el clic manual para el jugador en estos botones
				icon_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE 
				
				# --- CREACIÓN DEL CANDADO POR CÓDIGO ---
				var lock = TextureRect.new()
				lock.texture = LOCK_ICON
				lock.ignore_texture_size = true
				lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				lock.set_anchors_preset(Control.PRESET_FULL_RECT)
				lock.mouse_filter = Control.MOUSE_FILTER_IGNORE 
				lock.hide() 
				
				slot.add_child(lock)
				enemy_lock_overlays.append(lock)
			
			var box_red = slot.get_node_or_null("BoxRed")
			var box_green = slot.get_node_or_null("BoxBlue") 
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

## Updates the visual lock/unlock state of the enemy's abilities based on their current mana.
func _update_enemy_locked_skills(pool: Dictionary):
	for i in range(enemy_equipped_abilities.size()):
		if i >= enemy_lock_overlays.size() or enemy_lock_overlays[i] == null or enemy_equipped_abilities[i] == null:
			continue
			
		var ability = enemy_equipped_abilities[i]
		var lock = enemy_lock_overlays[i]
		var btn = enemy_magic_buttons[i]
		
		# Check if the enemy has enough mana
		if pool.get("red", 0) < ability.cost_red or \
		   pool.get("blue", 0) < ability.cost_blue or \
		   pool.get("green", 0) < ability.cost_green:
			lock.show()
			if btn: btn.modulate = Color(0.5, 0.5, 0.5) # Darken the button
		else:
			lock.hide()
			if btn: btn.modulate = Color.WHITE # Return to normal color

func _update_lives_hud(current_lives: int, time_left: int):
	# Actualizamos la barra (recuerda que el Max Value de la barra debe ser 5)
	if lives_label: 
		lives_label.text = str(current_lives) + "/5"
	
	if lives_bar:
		lives_bar.value = current_lives
		
	if timer_label:
		if current_lives >= 5:
			# Podés elegir poner "MAX" o "30:00". "MAX" suele quedar mejor.
			timer_label.text = "MAX" 
		else:
			# Formatear los segundos a MM:SS
			var mins = floor(time_left / 60.0)
			var secs = time_left % 60
			timer_label.text = "%02d:%02d" % [mins, secs]

func _update_fragments_hud(amount: int):
	if fragments_label: 
		fragments_label.text = str(amount)

func _show_lives_popup():
	if lives_purchase_popup: 
		lives_purchase_popup.show()

func _on_buy_lives_pressed():
	var cost = 50 # El costo en fragmentos de Poseidón
	var lives_to_give = 5 # <-- Ajustado a 5 vidas
	
	if LifeManager.buy_lives_with_fragments(lives_to_give, cost):
		print("GameUI: Vidas compradas con éxito.")
		lives_purchase_popup.hide()
		# Recargamos el nivel para que la grilla intente spawnear de nuevo
		get_tree().reload_current_scene()
	else:
		print("GameUI: No tienes suficientes fragmentos.")
		# Animación visual de rechazo (tiembla el botón)
		var tween = create_tween()
		var original_x = btn_buy_lives.position.x
		tween.tween_property(btn_buy_lives, "position:x", original_x + 10, 0.05)
		tween.tween_property(btn_buy_lives, "position:x", original_x - 10, 0.05)
		tween.tween_property(btn_buy_lives, "position:x", original_x, 0.05)
		btn_buy_lives.modulate = Color.RED
		tween.tween_property(btn_buy_lives, "modulate", Color.WHITE, 0.2)

func _spawn_magic_dust(start_pos: Vector2, piece_type: int, is_enemy: bool):
	# Si no hay escena cargada, no hacemos nada
	if not magic_dust_scene: 
		print("❌ ERROR: magic_dust_scene no está asignada en el Inspector de GameUI")
		return
	
	var dust_type = ""
	var target_node: Marker2D = null
	
	# Mapeo de tipos: Elegimos el target dependiendo de si es el turno del enemigo o no
	match piece_type:
		0: 
			dust_type = "mana_red"
			target_node = target_enemy_mana_red if is_enemy else target_mana_red
		1: 
			dust_type = "mana_blue"
			target_node = target_enemy_mana_blue if is_enemy else target_mana_blue
		2: 
			dust_type = "mana_green"
			target_node = target_enemy_mana_green if is_enemy else target_mana_green
		5: 
			dust_type = "gold"
			target_node = target_enemy_gold if is_enemy else target_gold
		6: 
			dust_type = "xp"
			target_node = target_enemy_xp if is_enemy else target_xp
		_: 
			return # Bomba o Timón no tienen dust
			
	var end_pos: Vector2
	if target_node == null:
		end_pos = get_viewport().get_visible_rect().size / 2.0
	else:
		end_pos = target_node.global_position
	
	var dust = magic_dust_scene.instantiate()
	add_child(dust)
	dust.fly_to_hud(start_pos, end_pos, dust_type)

# --- PAUSE MENU LOGIC ---

func _unhandled_input(event):
	# Si apretamos Escape y no estamos en Game Over
	if event.is_action_pressed("ui_cancel") and GameManager.current_state != GameManager.GameState.GAME_OVER:
		_toggle_pause()
		
	# --- TRUCO DE DEBUG: FORZAR VICTORIA (Tecla F9) ---
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		print("DEBUG: ¡Forzando victoria instantánea!")
		SignalBus.game_over.emit(true)
		
	# --- TRUCO DE DEBUG: RECARGA DE RECURSOS (Tecla T) ---
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		LifeManager.cheat_max_resources()

func _toggle_pause():
	var is_paused = get_tree().paused
	if is_paused:
		_resume_game()
	else:
		_pause_game()

func _pause_game():
	get_tree().paused = true
	GameManager.change_state(GameManager.GameState.PAUSED)
	pause_menu_panel.show()

func _resume_game():
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)
	pause_menu_panel.hide()

func _go_to_main_menu():
	# ¡VITAL! Siempre despausar el árbol antes de cambiar de escena
	get_tree().paused = false 
	GameManager.change_state(GameManager.GameState.MENU)
	
	print("GameUI: Volviendo al menú principal...")
	# Acá pones la ruta real de tu escena de menú principal cuando la tengas.
	# get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_reload_pressed():
	# Siempre despausar antes de recargar por si venimos de un estado pausado
	get_tree().paused = false
	get_tree().reload_current_scene()
	print("Partida reiniciada")

func _on_next_pressed():
	# Aquí irá la lógica de cambio de nivel a futuro
	print("Cargando siguiente nivel...")
	# get_tree().change_scene_to_file("res://Scenes/Levels/Level_02.tscn")
