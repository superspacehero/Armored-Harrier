extends GameThing
class_name BulletThing

func _init():
	thing_type = "Bullet"

@export var life = 1.0
var life_timer = 0.0

@export var muzzle_flash : GPUParticles3D
@export var bullet : Node3D
@export var bullet_speed = 200

func _ready():
	life_timer = 0.0
	muzzle_flash.emitting = true

	bullet.position = Vector3(0, 0, 0)
	bullet.visible = true
	bullet.process_mode = Node.PROCESS_MODE_INHERIT

func _process(delta):
	bullet.position += bullet.basis.z * delta * bullet_speed

	life_timer += delta
	if life_timer > life:
		GameManager.instance.bullet_pool.return_object_to_pool(self)

		bullet.visible = false
		bullet.process_mode = Node.PROCESS_MODE_DISABLED

		muzzle_flash.get_parent().remove_child(muzzle_flash)
		self.add_child(muzzle_flash)