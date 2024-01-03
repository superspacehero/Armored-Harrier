extends HandheldThing
class_name GunThing

@export var fire_point : Node3D

@export var bullet_rate : float = 0.1

var bullet_timer : float = 0

func attack(attacking : bool):
	super.attack(attacking)

func secondary_attack(attacking : bool):
	super.secondary_attack(attacking)

func _process(delta):
	super._process(delta)

	if _attacking:
		if bullet_timer < bullet_rate:
			bullet_timer += delta
		else:
			bullet_timer = 0

			var bullet: BulletThing = GameManager.instance.bullet_pool.get_object_from_pool(fire_point.global_position)
			bullet.rotation = global_rotation

			bullet.muzzle_flash.get_parent().remove_child(bullet.muzzle_flash)
			fire_point.add_child(bullet.muzzle_flash)
			bullet.muzzle_flash.position = Vector3(0, 0, 0)
			bullet.muzzle_flash.global_scale(Vector3.ONE)

			# bullet.bullet.linear_velocity = bullet.global_basis.z * bullet.bullet_speed