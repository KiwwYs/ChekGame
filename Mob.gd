extends CharacterBody3D

@export var min_speed := 10.0
@export var max_speed := 18.0

func _ready() -> void:
	# Mob อยู่ Layer 3
	collision_layer = 1 << 2
	# ชนพื้น (L2) + ผู้เล่น (L1) เท่านั้น  -> ไม่ชนม็อบด้วยกันเอง
	collision_mask  = (1 << 1) | (1 << 0)
	add_to_group("mob")

func _physics_process(delta: float) -> void:
	move_and_slide()

func initialize(start_position: Vector3) -> void:
	global_transform.origin = start_position
	var direction := (Vector3.ZERO - start_position).normalized()
	velocity = direction * randf_range(min_speed, max_speed)
	look_at_from_position(start_position, start_position + direction, Vector3.UP)

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free()
