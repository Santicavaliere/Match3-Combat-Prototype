extends State
class_name EnemyTakeDamage

func enter():
	print("Enemigo: Entrando en estado TAKE_DAMAGE")
	
	# 1. Hacemos que el barco parpadee en rojo y se encoja un poco
	context.sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(context.sprite, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(context.sprite, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(context.sprite, "modulate", Color.WHITE, 0.3).set_delay(0.2)
	
	# 2. Mostramos el número flotante
	show_damage_number(context.last_damage_received)
	
	# 3. Volvemos al estado Idle cuando termina el golpe
	tween.tween_callback(finish_damage)

func show_damage_number(amount: int):
	# Creamos un texto nuevo por código
	var label = Label.new()
	label.text = "-" + str(amount)
	
	# Le damos estilo (Rojo con borde negro para que se lea bien)
	label.add_theme_font_size_override("font_size", 45)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) # Rojo brillante
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	
	# Lo posicionamos un poquito arriba del centro del barco
	label.position = Vector2(-20, -60) 
	label.z_index = 100 # Para que aparezca por encima de todo
	
	# Lo agregamos a la escena
	context.add_child(label)
	
	# Animación del texto (flota hacia arriba y desaparece)
	var text_tween = create_tween()
	text_tween.set_parallel(true)
	text_tween.tween_property(label, "position:y", -100.0, 1.0).as_relative()
	text_tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	
	# Borramos el texto cuando termina la animación
	text_tween.tween_callback(label.queue_free).set_delay(1.0)

func finish_damage():
	# Buscamos el CombatManager de forma segura en la escena actual
	var combat_manager = get_tree().current_scene.get_node("CombatManager")
	
	# IMPORTANTE: Solo volvemos a Idle si el barco sigue vivo. 
	# El 'if combat_manager' evita cualquier crasheo futuro por null.
	if combat_manager and combat_manager.enemy_hp > 0:
		state_machine.change_state(state_machine.get_node("Idle"))
