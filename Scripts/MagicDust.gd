extends AnimatedSprite2D
class_name MagicDust

# Configuración del rastro
var p0: Vector2 
var p1: Vector2 
var p2: Vector2 

# CAMBIO 1: Actualizamos el tipo a CPUParticles2D
var _trail_node: CPUParticles2D 

func fly_to_hud(start_pos: Vector2, end_pos: Vector2, dust_type: String):
	# 1. Configuración inicial
	self.position = start_pos 
	self.scale = Vector2(0.1, 0.1) 
	self.z_index = 4000
	self.z_as_relative = false
	self.modulate = Color.WHITE
	self.show()
	
	_trail_node = get_node_or_null("Trail")
	
	# 2. CONFIGURACIÓN DINÁMICA DEL COLOR (LIMPIA PARA PARTÍCULAS)
	if _trail_node:
		# CAMBIO 2: Primero CREAMOS la variable
		var color_magia = Color.WHITE 
		
		# Segundo, averiguamos QUÉ color es (Usando valores HDR > 1.0 para más intensidad)
		match dust_type:
			# El 4to valor (0.5) hace que cada chispa sea semitransparente.
			# Al superponerse en modo Aditivo, crean un brillo suave sin quemarse.
			"mana_red": color_magia = Color(1.3, 0.2, 0.2, 0.2)
			"mana_blue": color_magia = Color(0.2, 0.8, 1.5, 0.2)
			"mana_green": color_magia = Color(0.3, 1.5, 0.3, 0.2)
			"gold", "xp": color_magia = Color(1.5, 1.2, 0.3, 0.2)
		
		# Tercero y último, se lo aplicamos a las partículas
		_trail_node.color = color_magia

	# 3. ANIMACIÓN
	if sprite_frames != null and sprite_frames.has_animation(dust_type):
		self.play(dust_type)
	
	p0 = start_pos
	p2 = end_pos
	
	# Curvatura
	var distance = p0.distance_to(p2)
	var direction = (p2 - p0).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	p1 = p0.lerp(p2, 0.5) + (perpendicular * randf_range(-0.3, 0.3) * distance)
	
	var tween = create_tween()
	# Viaje de 1.0 segundos
	tween.tween_method(_update_bezier_pos, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.parallel().tween_property(self, "scale", Vector2(0.3, 0.3), 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.7)
	
	tween.tween_callback(queue_free)

func _update_bezier_pos(t: float):
	var u = 1.0 - t
	var old_pos = self.position 
	var new_pos = (u * u * p0) + (2.0 * u * t * p1) + (t * t * p2)
	self.position = new_pos
	
	# Rotación
	if new_pos.distance_to(old_pos) > 0.1:
		self.rotation = old_pos.angle_to_point(new_pos) + PI
