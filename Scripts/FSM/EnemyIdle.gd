extends State
class_name EnemyIdle

func enter():
	print("Enemigo: Entrando en estado IDLE")
	# Nos aseguramos de que el sprite vuelva a la normalidad por si venimos de un ataque o daño
	context.sprite.modulate = Color.WHITE
	context.sprite.scale = Vector2(1.0, 1.0)
	context.sprite.play("default")

func exit():
	pass

func update(_delta: float):
	# Acá en el futuro pondremos la lógica de "si es mi turno, paso a atacar"
	pass
