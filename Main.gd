extends Node3D

@export var mob_scene: PackedScene
@export var player_node: CharacterBody3D

var score: int = 0
var game_over: bool = false

@onready var ui_root: Node = get_node_or_null("UserInterface")
@onready var score_label: Label = get_node_or_null("UserInterface/ScoreLabel")

var retry_panel: Control
var retry_label: Label
var retry_button: Button

func _ready() -> void:
	_ensure_world_floor()
	_ensure_retry_ui()
	_update_score_label()

	if player_node:
		player_node.player_squashed_mob.connect(on_mob_squashed)
		player_node.hit.connect(on_game_over)

	$MobTimer.timeout.connect(on_mob_timer_timeout)
	$MobTimer.start()

func on_mob_timer_timeout() -> void:
	if game_over:
		return
	var mob := mob_scene.instantiate()
	add_child(mob)
	mob.initialize(_random_spawn())

func _random_spawn() -> Vector3:
	var p := player_node.global_transform.origin
	var a := randf() * TAU
	var r := 50.0
	return Vector3(p.x + r * cos(a), p.y, p.z + r * sin(a))

func on_mob_squashed() -> void:
	score += 1
	_update_score_label()

func on_game_over() -> void:
	game_over = true
	$MobTimer.stop()
	_show_retry_ui()

func _update_score_label() -> void:
	if score_label:
		score_label.text = "Score: %d" % score

func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func _show_retry_ui() -> void:
	if retry_label:
		retry_label.text = "Game Over"
	retry_panel.visible = true

func _ensure_retry_ui() -> void:
	if ui_root == null:
		ui_root = CanvasLayer.new()
		ui_root.name = "UserInterface"
		add_child(ui_root)

	retry_panel = ui_root.get_node_or_null("Retry") as Control
	if retry_panel == null:
		retry_panel = PanelContainer.new()
		retry_panel.name = "Retry"
		ui_root.add_child(retry_panel)

	retry_panel.visible = false
	retry_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# จัดกึ่งกลางจอ
	retry_panel.anchor_left = 0.5
	retry_panel.anchor_top = 0.5
	retry_panel.anchor_right = 0.5
	retry_panel.anchor_bottom = 0.5
	retry_panel.offset_left = -180
	retry_panel.offset_right = 180
	retry_panel.offset_top = -100
	retry_panel.offset_bottom = 100

	# VBoxContainer สำหรับจัดเรียงข้อความแนวตั้ง
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.anchor_left = 0
	vbox.anchor_right = 1
	vbox.anchor_top = 0
	vbox.anchor_bottom = 1
	vbox.offset_left = 0
	vbox.offset_top = 0
	vbox.offset_right = 0
	vbox.offset_bottom = 0
	retry_panel.add_child(vbox)

	# Label: "Game Over"
	retry_label = Label.new()
	retry_label.name = "Label"
	retry_label.text = "Game Over"
	retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(retry_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	# Button: "Play Again"
	retry_button = Button.new()
	retry_button.name = "PlayAgain"
	retry_button.text = "Play Again"
	retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(retry_button)

	# กดแล้วรีโหลดเกม
	retry_button.pressed.connect(_on_play_again_pressed)

	# ซ่อนตอนเริ่ม
	retry_panel.visible = false



func _ensure_world_floor() -> void:
	var found := false

	for n in find_children("", "StaticBody3D", true, true):
		var sb := n as StaticBody3D
		if sb:
			sb.collision_layer = 1 << 1
			sb.collision_mask = (1 << 0) | (1 << 2)
			found = true

	if found:
		return

	var floor := StaticBody3D.new()
	floor.name = "_AutoFloor"
	floor.collision_layer = 1 << 1
	floor.collision_mask = (1 << 0) | (1 << 2)
	add_child(floor)

	var shape := BoxShape3D.new()
	shape.size = Vector3(200, 1, 200)

	var col := CollisionShape3D.new()
	col.shape = shape

	var y := 0.0
	if player_node != null:
		y = player_node.global_transform.origin.y - 0.6
	col.transform.origin = Vector3(0, y, 0)

	floor.add_child(col)
	print("AUTO: created _AutoFloor at y=", y)
