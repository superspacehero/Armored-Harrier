extends HandheldThing
class_name GunThing

@export var fire_point : Node3D

@export var bullet_damage : int = 1
@export var bullet_rate : float = 0.25

func _get_damage_amount() -> int:
	return bullet_damage

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

			if character.target != null:
				bullet.look_at(character.target.thing_bottom.global_position.lerp(character.target.thing_top.global_position, 0.5), Vector3.UP, true)
			else:
				bullet.rotation = global_rotation

			bullet.damage_amount = _get_damage_amount()
			bullet.muzzle_flash.get_parent().remove_child(bullet.muzzle_flash)
			fire_point.add_child(bullet.muzzle_flash)
			bullet.muzzle_flash.position = Vector3(0, 0, 0)
			bullet.muzzle_flash.global_scale(Vector3.ONE)

			# bullet.bullet.linear_velocity = bullet.global_basis.z * bullet.bullet_speed
