extends CharacterBody3D

@export var speed := 20.0
@export var fall_acceleration := 75.0
@export var jump_impulse := 20.0

signal player_squashed_mob
signal hit

func _ready() -> void:
	_setup_input()

	# Player อยู่ Layer 1
	collision_layer = 1 << 0
	# ชนพื้น (L2) + ชนม็อบ (L3)
	collision_mask  = (1 << 1) | (1 << 2)

	floor_snap_length = 0.25
	safe_margin = 0.05
	add_to_group("player")
	_ensure_player_collider()
	global_transform.origin.y += 0.1


func _ensure_player_collider() -> void:
	var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null:
		cs = CollisionShape3D.new()
		add_child(cs)
	if cs.shape == null:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.4
		cap.height = 1.2                 # total ~ 2.0 (height + 2*radius)
		cs.shape = cap
		cs.transform.origin = Vector3(0, 0.9, 0) # ให้ก้นแคปซูลอยู่ต่ำกว่าจุดกำเนิดนิดเดียว

func _physics_process(delta: float) -> void:
	var v := velocity

	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_right"):   dir.x += 1.0
	if Input.is_action_pressed("move_left"):    dir.x -= 1.0
	if Input.is_action_pressed("move_back"):    dir.z += 1.0
	if Input.is_action_pressed("move_forward"): dir.z -= 1.0
	if dir != Vector3.ZERO:
		dir = dir.normalized()
		if has_node("Pivot"):
			$Pivot.basis = Basis.looking_at(dir, Vector3.UP)

	v.x = dir.x * speed
	v.z = dir.z * speed

	if not is_on_floor():
		v.y -= fall_acceleration * delta
	elif Input.is_action_just_pressed("jump"):
		v.y = jump_impulse
	else:
		v.y = -0.1

	velocity = v
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		var col := c.get_collider()
		if col and col.is_in_group("mob"):
			if Vector3.UP.dot(c.get_normal()) > 0.1:
				emit_signal("player_squashed_mob")
				col.queue_free()
				velocity.y = jump_impulse
			else:
				emit_signal("hit")
				queue_free()
				return


# ----- INPUT SETUP (อัตโนมัติ) -----
func _setup_input() -> void:
	# ถ้ามีอยู่แล้วจะไม่สร้างซ้ำ
	_ensure_action("move_right",  [Key.KEY_D, Key.KEY_RIGHT])
	_ensure_action("move_left",   [Key.KEY_A, Key.KEY_LEFT])
	_ensure_action("move_forward",[Key.KEY_W, Key.KEY_UP])
	_ensure_action("move_back",   [Key.KEY_S, Key.KEY_DOWN])
	_ensure_action("jump",        [Key.KEY_SPACE])  # Space bar

func _ensure_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k      # ใช้คีย์ตามแป้นจริง
		ev.keycode = k               # เผื่อเคสเลย์เอาต์
		InputMap.action_add_event(action_name, ev)
