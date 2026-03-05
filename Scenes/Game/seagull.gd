extends AnimatedSprite2D

func _ready():
	# Aseguramos que la animación esté corriendo
	play("default")
	
	# --- NUEVO: PREPARAMOS LA APARICIÓN ---
	# Guardamos el tamaño que le asignó el Spawner (o el editor)
	var target_scale = scale 
	# La hacemos nacer invisible y mucho más pequeña de lo normal
	modulate.a = 0.0
	scale = target_scale * 0.1 
	
	# Le damos un tiempo de vida aleatorio entre 6 y 10 segundos
	var flight_duration = randf_range(6.0, 10.0)
	var random_drift = randf_range(-60.0, 60.0) 
	
	var tween = create_tween()
	# Ponemos TODO el tween en paralelo
	tween.set_parallel(true)
	
	# --- FASE 1: APARICIÓN SUAVE (Dura 1.5 segundos) ---
	# Pasa de invisible a visible
	tween.tween_property(self, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	# Crece desde chiquita hasta su tamaño objetivo (da la sensación de acercarse/aparecer)
	tween.tween_property(self, "scale", target_scale, 1.5).set_trans(Tween.TRANS_SINE)
	
	# --- FASE 2: EL VUELO (Empieza DESPUÉS de 1.5 segundos) ---
	# Usamos .set_delay(1.5) para que estas acciones esperen a que termine la Fase 1
	
	# 1. Se aleja (se hace muy chiquita, hasta casi 0)
	tween.tween_property(self, "scale", Vector2(0.01, 0.01), flight_duration).set_delay(1.5).set_ease(Tween.EASE_IN)
	
	# 2. Sube hacia el horizonte y se desvía un poquito
	tween.tween_property(self, "position:y", -100.0, flight_duration).as_relative().set_delay(1.5)
	tween.tween_property(self, "position:x", random_drift, flight_duration).as_relative().set_delay(1.5)
	
	# 3. Se desvanece suavemente a lo lejos
	tween.tween_property(self, "modulate:a", 0.0, flight_duration).set_delay(1.5).set_ease(Tween.EASE_IN)
	
	# --- FASE 3: ELIMINAR ---
	# Sumamos el tiempo de aparición (1.5) + el de vuelo para saber cuándo borrarla
	tween.set_parallel(false)
	tween.tween_callback(self.queue_free).set_delay(1.5 + flight_duration)
