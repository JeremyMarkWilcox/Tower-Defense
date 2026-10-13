extends Node3D

const bulletScene = preload("res://game/data/towers/bullet.tscn")

@export var range_one: Area3D
@export var range_two: Area3D
@export var range_three: Area3D

@export var twrFireRate := 2000
@export var twrDamage := 1
@export var twrBulletSpeed := 10
@export var twrMesh: MeshInstance3D
@export var turnRate := 5

var targetEnemy: Node3D = null

func _ready() -> void:
	_draw_debug_line()

func _process(delta: float) -> void:
	if targetEnemy == null or not is_instance_valid(targetEnemy):
		var bodies := range_three.get_overlapping_areas()
		if bodies.size() > 0:
			targetEnemy = bodies[0] # Pick the first enemy in range
		else:
			targetEnemy = null
			return
	
	var direction := targetEnemy.global_position - global_position
	var target_angle := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, turnRate * delta)

#ai debug front direction code
func _draw_debug_line() -> void:
	# We will use ImmediateMesh to draw a line from the tower center forward
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	
	# Make a simple material so the line is bright red
	var mat := ORMMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.RED
	mi.material_override = mat
	
	add_child(mi)
	
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(Vector3.ZERO)
	im.surface_add_vertex(Vector3(0, 0, -3)) # Draws 3 units down the local negative Z (Forward) axis
	im.surface_end()
