extends Node
class_name GameManager

static var instance = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if instance == null:
		instance = self

@export_category("Object Pools")
@export var bullet_pool : ObjectPool
