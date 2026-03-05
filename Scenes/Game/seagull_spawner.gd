extends Node

@export var seagull_scene: PackedScene
@onready var timer = $Timer

func _ready():
	# 1. Conectamos la señal de fin de juego para detener la fábrica de gaviotas
	SignalBus.game_over.connect(_on_game_over)
	
	# 2. Conectamos el Timer por código
	timer.timeout.connect(_on_timer_timeout)
	
	# 3. Arrancamos el primer temporizador aleatorio
	start_random_timer()

func _on_timer_timeout():
	spawn_seagull()
	start_random_timer() # Volvemos a sortear un tiempo para la próxima

func start_random_timer():
	# Sortea un tiempo de espera. Aparecerá una gaviota entre cada 4 y 12 segundos.
	# (Podés cambiar estos números a tu gusto)
	timer.start(randf_range(4.0, 12.0))

func spawn_seagull():
	if not seagull_scene: 
		print("Error: No cargaste la escena de la gaviota en el Spawner")
		return
		
	var seagull = seagull_scene.instantiate()
	
	# Le damos una posición de inicio aleatoria en el cielo
	# Ajustá los valores de X e Y para que coincidan con la parte de arriba de tu océano
	var random_x = randf_range(100.0, 1100.0) 
	var random_y = randf_range(50.0, 200.0)
	seagull.position = Vector2(random_x, random_y)
	
	# --- CORRECCIÓN DE TAMAÑO INICIAL ---
	# Las hacemos nacer MUY pequeñitas en la distancia
	var random_scale = randf_range(0.05, 0.15) 
	seagull.scale = Vector2(random_scale, random_scale)
	
	# La agregamos a la escena
	add_child(seagull)

func _on_game_over(_player_won: bool):
	timer.stop()
	print("Juego terminado: El cielo se despeja.")
