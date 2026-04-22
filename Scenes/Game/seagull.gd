extends AnimatedSprite2D

func _ready():
	
	play("default")
	
	var target_scale = scale 
	
	modulate.a = 0.0
	scale = target_scale * 0.1 
	
	
	var flight_duration = randf_range(6.0, 10.0)
	var random_drift = randf_range(-60.0, 60.0) 
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	
	
	tween.tween_property(self, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(self, "scale", target_scale, 1.5).set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(self, "scale", Vector2(0.01, 0.01), flight_duration).set_delay(1.5).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", -100.0, flight_duration).as_relative().set_delay(1.5)
	tween.tween_property(self, "position:x", random_drift, flight_duration).as_relative().set_delay(1.5)
	
	tween.tween_property(self, "modulate:a", 0.0, flight_duration).set_delay(1.5).set_ease(Tween.EASE_IN)
	
	tween.set_parallel(false)
	tween.tween_callback(self.queue_free).set_delay(1.5 + flight_duration)
