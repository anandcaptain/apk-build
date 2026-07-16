extends Node2D

const GRAVITY := 900.0
const FLAP_STRENGTH := -300.0
const PIPE_SPEED := 150.0
const PIPE_GAP := 190.0
const PIPE_INTERVAL := 1.5
const PIPE_WIDTH := 60.0
const BIRD_SIZE := Vector2(34, 24)

var bird: Area2D
var bird_velocity := 0.0
var pipes: Array = []
var spawn_timer := 0.0
var score := 0
var started := false
var game_over := false

var score_label: Label
var msg_label: Label
var sky: ColorRect
var ground: ColorRect

func _ready() -> void:
	randomize()
	var vp := get_viewport_rect().size

	sky = ColorRect.new()
	sky.size = vp
	sky.color = Color(0.45, 0.75, 0.95)
	add_child(sky)

	ground = ColorRect.new()
	ground.size = Vector2(vp.x, 40)
	ground.position = Vector2(0, vp.y - 40)
	ground.color = Color(0.82, 0.68, 0.35)
	add_child(ground)

	_setup_bird()

	score_label = Label.new()
	score_label.position = Vector2(20, 20)
	score_label.add_theme_font_size_override("font_size", 32)
	add_child(score_label)

	msg_label = Label.new()
	msg_label.text = "Tap / Space to start"
	msg_label.position = Vector2(vp.x / 2 - 110, vp.y / 2 - 40)
	msg_label.add_theme_font_size_override("font_size", 24)
	add_child(msg_label)

	_update_score_label()

func _setup_bird() -> void:
	bird = Area2D.new()
	bird.position = Vector2(120, get_viewport_rect().size.y / 2)
	bird.collision_layer = 1
	bird.collision_mask = 2

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BIRD_SIZE
	shape.shape = rect
	bird.add_child(shape)

	var visual := ColorRect.new()
	visual.size = BIRD_SIZE
	visual.position = -BIRD_SIZE / 2
	visual.color = Color(1.0, 0.8, 0.1)
	bird.add_child(visual)

	bird.area_entered.connect(func(_a): _die())
	add_child(bird)

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventMouseButton and event.pressed:
		pressed = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		pressed = true
	if pressed:
		_flap()

func _flap() -> void:
	if game_over:
		_reset_game()
		return
	started = true
	msg_label.visible = false
	bird_velocity = FLAP_STRENGTH

func _process(delta: float) -> void:
	if not started or game_over:
		return

	bird_velocity += GRAVITY * delta
	bird.position.y += bird_velocity * delta

	var vp := get_viewport_rect().size
	if bird.position.y < 0 or bird.position.y > vp.y - 40:
		_die()
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = PIPE_INTERVAL
		_spawn_pipe()

	for pair in pipes.duplicate():
		pair.position.x -= PIPE_SPEED * delta
		if not pair.get_meta("scored") and pair.position.x < bird.position.x:
			pair.set_meta("scored", true)
			score += 1
			_update_score_label()
		if pair.position.x < -PIPE_WIDTH:
			pipes.erase(pair)
			pair.queue_free()

func _spawn_pipe() -> void:
	var vp := get_viewport_rect().size
	var gap_y := randf_range(150, vp.y - 190)

	var pair := Node2D.new()
	pair.position = Vector2(vp.x + PIPE_WIDTH, 0)
	pair.set_meta("scored", false)

	var top_len := gap_y - PIPE_GAP / 2.0
	var bottom_len := (vp.y - 40) - (gap_y + PIPE_GAP / 2.0)

	pair.add_child(_make_pipe_segment(top_len, top_len / 2.0))
	pair.add_child(_make_pipe_segment(bottom_len, vp.y - 40 - bottom_len / 2.0))

	add_child(pair)
	pipes.append(pair)

func _make_pipe_segment(length: float, center_y: float) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 2
	area.collision_mask = 1
	area.position = Vector2(0, center_y)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(PIPE_WIDTH, max(length, 1.0))
	shape.shape = rect
	area.add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(PIPE_WIDTH, max(length, 1.0))
	visual.position = Vector2(-PIPE_WIDTH / 2, -length / 2)
	visual.color = Color(0.2, 0.7, 0.2)
	area.add_child(visual)

	return area

func _update_score_label() -> void:
	score_label.text = "Score: %d" % score

func _die() -> void:
	if game_over:
		return
	game_over = true
	msg_label.text = "Game Over - Score: %d\nTap to restart" % score
	msg_label.visible = true

func _reset_game() -> void:
	for p in pipes:
		p.queue_free()
	pipes.clear()

	score = 0
	_update_score_label()
	bird_velocity = 0.0
	bird.position = Vector2(120, get_viewport_rect().size.y / 2)

	game_over = false
	started = false
	msg_label.text = "Tap / Space to start"
	msg_label.visible = true
