extends GameThing
class_name BulletThing

func _init():
	thing_type = "Bullet"

@export var life = 1.0
var life_timer = 0.0

@export var damage_amount = 1

@export_category("Effects")
@export var muzzle_flash : GPUParticles3D
@export var bullet_impact : GPUParticles3D

@export_category("Physics")
@export var bullet : RigidBody3D
@export var bullet_speed = 200

func set_bullet_active(active):
	bullet.visible = active
	bullet.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _ready():
	life_timer = 0.0
	muzzle_flash.emitting = true
	bullet_impact.emitting = false

	bullet.position = Vector3(0, 0, 0)
	
	set_bullet_active(true)

func _process(delta):
	life_timer += delta
	if life_timer > life:
		GameManager.instance.bullet_pool.return_object_to_pool(self)

		set_bullet_active(false)

		muzzle_flash.get_parent().remove_child(muzzle_flash)
		self.add_child(muzzle_flash)

func _physics_process(delta) -> void:
	var collision : KinematicCollision3D = bullet.move_and_collide(self.global_basis.z * bullet_speed * delta)
	if collision and bullet.process_mode != Node.PROCESS_MODE_DISABLED:
		set_bullet_active(false)
		bullet_impact.position = bullet.position
		bullet_impact.emitting = true

		# Damage the thing we hit
		var collider_thing = collision.get_collider()
		
		while collider_thing:
			if collider_thing is GameThing:
				var game_thing : GameThing = collider_thing as GameThing
				game_thing.damage(damage_amount)
				break
			collider_thing = collider_thing.get_parent()
