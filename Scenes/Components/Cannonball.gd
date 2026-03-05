extends Node2D
class_name Cannonball

@onready var shot_sprite = $ShotSprite
@onready var bullet_sprite = $BulletSprite

func _ready():
	# Este script se ejecuta en cuanto la bala nace físicamente.
	# Vamos a programar su transición visual.
	start_visual_transition()

func start_visual_transition():
	var transition_tween = create_tween()
	
	# FASE 1: Detonación inicial (Pequño delay)
	# Mantenemos la imagen de humo y fuego visible un instante (0.15s)
	transition_tween.tween_interval(0.15)
	
	# FASE 2: Transición paralela (Cross-Fade)
	# Ponemos el tween en modo paralelo para que ambas acciones ocurran JUNTAS.
	transition_tween.set_parallel(true)
	
	# 1. Hacemos desvanecer la imagen del disparo (de Modulate Alpha 1 a 0)
	# Esto tarda 0.25 segundos y se suaviza al final.
	transition_tween.tween_property(shot_sprite, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_OUT)
	
	# 2. Hacemos aparecer la imagen de la bala volando (de Modulate Alpha 0 a 1)
	# Esto tarda los mismos 0.25 segundos.
	transition_tween.tween_property(bullet_sprite, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	
	# FASE 3: Limpieza visual (Volvemos a secuencial)
	transition_tween.set_parallel(false)
	
	# Una vez que la transición terminó, nos aseguramos de borrar el nodo visible inicial para no consumir memoria
	transition_tween.tween_callback(shot_sprite.queue_free)
