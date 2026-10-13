extends Area3D

@export var damage := 1000.0
@export var bulletSpeed := 1.0
@export var targetEnemy : Node3D
@export var hitParticle : PackedScene

var time := 0.0
var _has_hit := false
var _age := 0.0
const MAX_AGE := 4.0  # seconds; frees bullets whose target died mid-flight

func _ready() -> void:
	#prevents bullet from clipping through turret, may not be necessary if shot particle can cover it up
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * bulletSpeed
	if time > 1.5:
		visible = true
	#homes in on enemies since I couldn't get proper aim direction
	if is_instance_valid(targetEnemy):
		look_at(targetEnemy.global_position)
	position += -transform.basis.z * bulletSpeed * delta
	_age += delta
	if _age > MAX_AGE:
		queue_free()
	

func _on_area_entered(area: Area3D) -> void:
	if _has_hit or area.collision_layer != 2:
		return
	_has_hit = true  # two enemies in the same frame shouldn't double-hit
	var enemy := area.get_parent() as BaseEnemy
	if enemy:
		enemy.take_damage(int(damage))
	_spawn_effect(hitParticle)
	queue_free()


func _spawn_effect(scene: PackedScene) -> void:
	if scene == null:
		return
	var effect := scene.instantiate() as Node3D
	get_tree().current_scene.add_child(effect)  # part of the game scene, so restarts clean it up
	effect.global_position = global_position     # world position, not local
