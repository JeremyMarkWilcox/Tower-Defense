class_name ScreenEdge
## Finds where a direction from a point leaves what the camera can see, on the ground.

## Distance from `from` along `direction` to the screen edge, or `fallback` if it can't tell.
static func distance(camera: Camera3D, from: Vector3, direction: Vector3, fallback: float) -> float:
	var rect := camera.get_viewport().get_visible_rect()
	var screen_corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y),
			rect.end, Vector2(rect.position.x, rect.end.y)]
	var ground := Plane(Vector3.UP, from.y)
	var corners: Array[Vector2] = []
	for corner in screen_corners:
		var hit: Variant = ground.intersects_ray(camera.project_ray_origin(corner),
				camera.project_ray_normal(corner))
		if hit == null:
			return fallback
		var point: Vector3 = hit
		corners.append(Vector2(point.x, point.z))
	var origin := Vector2(from.x, from.z)
	var ray_end := origin + Vector2(direction.x, direction.z).normalized() * 10000.0
	var best := INF
	for i in corners.size():
		var crossing: Variant = Geometry2D.segment_intersects_segment(origin, ray_end,
				corners[i], corners[(i + 1) % corners.size()])
		if crossing != null:
			best = minf(best, origin.distance_to(crossing))
	return best if best < INF else fallback
