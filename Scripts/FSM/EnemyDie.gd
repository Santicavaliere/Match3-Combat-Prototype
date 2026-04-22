extends State
class_name EnemyDie

func enter():
	print("Enemigo: Entrando en estado DIE")
	
	
	context.sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	
	tween.tween_property(context.sprite, "position:y", 150.0, 1.5).as_relative()
	
	tween.tween_property(context.sprite, "modulate:a", 0.0, 1.5)
	
	tween.set_parallel(false)
	
	tween.tween_callback(context.queue_free)
