extends Area3D

@export var damage := 1000.0
@export var bulletSpeed := 1.0
@export var targetEnemy : Node3D
@export var hitParticle : PackedScene
@export var type : int
@export var level : int

## The look (core mesh + trail), set by the tower before the bullet enters the tree.
var visual_scene: PackedScene
var time := 0.0
var _has_hit := false
var _age := 0.0
const MAX_AGE := 4.0  # seconds; frees bullets whose target died mid-flight
var tower_data: TowerData

func _ready() -> void:
	#prevents bullet from clipping through turret, may not be necessary if shot particle can cover it up
	visible = false
	if visual_scene:
		add_child(visual_scene.instantiate())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * bulletSpeed
	if time > 1.5:
		visible = true
	#homes in on enemies since I couldn't get proper aim direction
	if is_instance_valid(targetEnemy):
		look_at(_aim_point())
	position += -transform.basis.z * bulletSpeed * delta
	_age += delta
	if _age > MAX_AGE:
		queue_free()
		
		
## The middle of the target's hitbox shape, so bullets fly at the body instead of the feet.
func _aim_point() -> Vector3:
	for child in targetEnemy.get_children():
		if child is CollisionShape3D:
			return child.global_position
	return targetEnemy.global_position + Vector3.UP * 0.8
	

func _on_area_entered(area: Area3D) -> void:
	if _has_hit or area.collision_layer != 2:
		return
	_has_hit = true  # two enemies in the same frame shouldn't double-hit
	var enemy := area.get_parent() as BaseEnemy
	if enemy:
		enemy.take_damage(int(damage))
		if tower_data:
			Audio.play_sfx(tower_data.get_hit_sound(type), 0.1, tower_data.hit_volume_db)
		if tower_data:
			_apply_effect(enemy)
	_spawn_effect(hitParticle)
	_release_trails()
	queue_free()


## Fire burns the target; Ice slows the target, or everything nearby at Ice 2.
func _apply_effect(enemy: BaseEnemy) -> void:
	match type:
		TowerData.FIRE:
			enemy.burn(tower_data.burn_duration[level], tower_data.burn_tick_damage[level])
		TowerData.ICE:
			var duration: float = tower_data.slow_duration[level]
			var amount: float = tower_data.slow_amount[level]
			var radius: float = tower_data.slow_radius[level]
			if radius <= 0.0:
				enemy.slow(duration, amount)
				return
			_spawn_nova(enemy.global_position, radius)
			for node in get_tree().get_nodes_in_group(&"enemies"):
				var other := node as BaseEnemy
				if other and other.global_position.distance_to(enemy.global_position) <= radius:
					other.slow(duration, amount)
										
	
	##special effects per tower type maybe not the best practice but it will work
	#fire
	if (type == 1):
		enemy.burn(1.0 * level, 2.0 * level)
	
	#ice
	if (type == 2):
		enemy.slow(1.0 * level, 30.0 * level)


func _spawn_nova(at: Vector3, radius: float) -> void:
	if tower_data.frost_nova == null:
		return
	var nova := tower_data.frost_nova.instantiate() as Node3D
	get_tree().current_scene.add_child(nova)  # restarts clean it up with the scene
	nova.global_position = at + Vector3.UP * 0.05  # just above the ground, so it doesn't flicker into it
	nova.play(radius)
	
	
func _spawn_effect(scene: PackedScene) -> void:
	if scene == null:
		return
	var effect := scene.instantiate() as Node3D
	get_tree().current_scene.add_child(effect)  # part of the game scene, so restarts clean it up
	effect.global_position = global_position     # world position, not local


## Hands trail particles to the scene so they fade out instead of vanishing with the bullet.
func _release_trails() -> void:
	for node in find_children("*", "CPUParticles3D", true, false):
		var trail := node as CPUParticles3D
		trail.reparent(get_tree().current_scene)  # keeps its world position
		trail.emitting = false
		get_tree().create_timer(trail.lifetime + 0.1, false).timeout.connect(trail.queue_free)
