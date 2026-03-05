extends State
class_name EnemyDie

func enter():
	print("Enemigo: Entrando en estado DIE")
	
	# Lo teñimos de gris oscuro para dar la sensación de derrota
	context.sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	
	var tween = create_tween()
	
	# Ponemos el tween en paralelo para que se hunda y se vuelva transparente AL MISMO TIEMPO
	tween.set_parallel(true)
	
	# Se hunde (baja 150 píxeles en Y durante 1.5 segundos)
	tween.tween_property(context.sprite, "position:y", 150.0, 1.5).as_relative()
	
	# Se desvanece (el canal Alpha pasa a 0.0)
	tween.tween_property(context.sprite, "modulate:a", 0.0, 1.5)
	
	# Volvemos a modo secuencial para el último paso
	tween.set_parallel(false)
	
	# Una vez que terminó la animación, borramos el nodo de la memoria
	tween.tween_callback(context.queue_free)
