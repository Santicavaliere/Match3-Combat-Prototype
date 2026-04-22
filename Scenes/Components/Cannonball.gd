extends Node2D
class_name Cannonball

@onready var trail = $BulletTrail
@onready var sprite = $BulletSprite

var last_pos: Vector2

func _ready():
	last_pos = global_position
	trail.play("default")

func _process(_delta):
	var velocity = global_position - last_pos
	
	if velocity.length() > 0.1:
		var dir = velocity.normalized()
		rotation = dir.angle()

	# la bala queda adelante automáticamente
	last_pos = global_position
