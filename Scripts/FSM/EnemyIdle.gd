extends State
class_name EnemyIdle

func enter():
	print("Enemigo: Entrando en estado IDLE")
	context.sprite.modulate = Color.WHITE
	context.sprite.scale = context.base_scale
	context.sprite.play("default")

func exit():
	pass

func update(_delta: float):
	
	pass
