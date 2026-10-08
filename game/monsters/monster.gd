class_name Monster
extends CharacterBody3D
## มอนที่ไล่ผู้เล่น: เดินตรวจ → ได้ยินเสียง/เห็น → ไล่ → ค้นหา → กลับไปเดินตรวจ (แบบ Little Nightmares)
## พฤติกรรมของแต่ละชนิดตั้งที่ profile (ไฟล์ .tres) · ตัวโมเดลใส่เป็นลูกชื่อ Model
## ต้องมีลูก: NavigationAgent3D และ Eye (Marker3D ที่ระดับตา)

enum State { IDLE, PATROL, INVESTIGATE, CHASE, SEARCH, FROZEN, CATCH }

signal state_changed(new_state: State)

## ค่าของมอนชนิดนี้
@export var profile: MonsterProfile
## จุดเดินตรวจ (Marker3D) เดินวนตามลำดับ · ว่าง = ยืนนิ่ง
@export var patrol_points: Array[Node3D] = []
## เริ่มเกมมาในสถานะไหน
@export var start_state: State = State.PATROL
## หลับอยู่: ไม่ใช้ตาหูจนกว่ากล่องเหตุการณ์จะปลุก (แบบแขก Guests ที่นั่งกินอยู่)
@export var dormant := false
## สีตัวมอน (ทับสีของโมเดล · โปร่งใสทั้งหมด = ใช้สีเดิมของโมเดล)
@export var model_tint := Color(0, 0, 0, 0)

var state: State = State.IDLE
## มอนรู้ตัวว่ามีผู้เล่นแค่ไหน 0–1 (ระบบเสียงหัวใจอ่านค่านี้)
var awareness := 0.0

var _player: Player
var _target := Vector3.ZERO
var _since_contact := 0.0
var _search_left := 0.0
var _patrol_index := 0
var _anim: AnimationPlayer
var _before_freeze: State = State.IDLE
var _dt := 0.016
var _hspeed := 0.0
var _cmd := 0.0
var _cmd_f := 0.0
var _moving := false
var _clip_cur := ""
var _rate_cur := 1.0

@onready var _agent: NavigationAgent3D = $NavigationAgent3D
@onready var _eye: Node3D = $Eye


func _ready() -> void:
	add_to_group("monster")
	# ใช้ get_node แทนชื่อ Autoload ตรง ๆ เพื่อให้สคริปต์สร้างฉาก (โหมด -s) โหลดไฟล์นี้ได้
	var bus := get_node_or_null("/root/NoiseBus")
	if bus:
		bus.noise.connect(_on_noise)
	_anim = _find_anim(get_node_or_null("Model"))
	_setup_model()
	await get_tree().physics_frame
	_player = get_tree().get_first_node_in_group("player") as Player
	_set_state(start_state)


func _physics_process(delta: float) -> void:
	_dt = delta
	if state == State.CATCH or profile == null:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	# แบบ Patients: โดนแสงแล้วหยุดนิ่ง
	if profile.frozen_by_light:
		var lit := _is_lit()
		if lit and state != State.FROZEN:
			_before_freeze = state
			_set_state(State.FROZEN)
		elif not lit and state == State.FROZEN:
			_set_state(_before_freeze)
		if state == State.FROZEN:
			_accelerate_to(Vector3.ZERO, delta, 30.0)
			move_and_slide()
			_update_anim(delta)
			return

	_update_senses(delta)

	match state:
		State.PATROL:
			if patrol_points.is_empty():
				_stop()
			elif _move_to(patrol_points[_patrol_index].global_position, profile.patrol_speed, delta):
				_patrol_index = (_patrol_index + 1) % patrol_points.size()
		State.INVESTIGATE:
			if _move_to(_target, profile.investigate_speed, delta):
				_start_search()
		State.CHASE:
			if _move_to(_target, profile.chase_speed, delta) and not _sees_player():
				_start_search()
			if _since_contact > profile.lose_target_time:
				_start_search()
			_try_catch()
		State.SEARCH:
			_search_left -= delta
			if _move_to(_target, profile.investigate_speed, delta):
				_target = _random_point_near(_target)
			if _search_left <= 0.0:
				_set_state(State.PATROL if not patrol_points.is_empty() else State.IDLE)
		State.IDLE:
			_stop()
	_update_anim(delta)


## ปลุกให้ไล่ผู้เล่นทันที (ใช้กับฝูงมอนแบบ Guests ที่เริ่มจากกล่องเหตุการณ์)
func wake_and_chase() -> void:
	dormant = false
	if _player:
		_target = _player.global_position
		_since_contact = 0.0
		_set_state(State.CHASE)


## หัวใจผู้เล่นควรเต้นแรงแค่ไหนเพราะมอนตัวนี้ (0–1) ตามที่ตั้งใน profile
func heartbeat_level(listener: Vector3) -> float:
	if profile == null or state == State.IDLE and dormant:
		return 0.0
	match profile.heartbeat:
		1:
			return awareness
		2:
			return clampf(1.0 - global_position.distance_to(listener) / profile.heartbeat_range, 0.0, 1.0)
	return 0.0


# ---------- ประสาทสัมผัส ----------

func _update_senses(delta: float) -> void:
	if _player == null or dormant:
		return
	_since_contact += delta
	var sees := _sees_player()
	var woke := profile.wake_distance > 0.0 and global_position.distance_to(_player.global_position) < profile.wake_distance
	if sees or woke:
		_since_contact = 0.0
		_target = _player.global_position
		if state != State.CHASE:
			_set_state(State.CHASE)


func _on_noise(pos: Vector3, loudness: float, source: Node) -> void:
	if profile == null or dormant or not profile.can_hear or state in [State.CATCH, State.FROZEN]:
		return
	if global_position.distance_to(pos) > loudness * profile.hearing_scale:
		return
	_target = pos
	if state == State.CHASE:
		# ตาบอดไล่ด้วยหู: เสียงจากตัวผู้เล่นทำให้ยังไล่ต่อ
		if source == _player:
			_since_contact = 0.0
	elif source == _player and not profile.can_see:
		_since_contact = 0.0
		_set_state(State.CHASE)
	else:
		_set_state(State.INVESTIGATE)


func _sees_player() -> bool:
	if not profile.can_see or _player == null:
		return false
	var head := _player.eye_position()
	var to := head - _eye.global_position
	if to.length() > profile.sight_range:
		return false
	if _player.is_hidden:
		var peek := profile.peek_hidden_distance > 0.0 and state == State.SEARCH \
			and global_position.distance_to(_player.global_position) < profile.peek_hidden_distance
		if not peek:
			return false
	var fwd := -global_basis.z
	if rad_to_deg(fwd.angle_to(Vector3(to.x, 0.0, to.z))) > profile.sight_fov_deg * 0.5:
		return false
	return _clear_line(_eye.global_position, head)


func _is_lit() -> bool:
	var chest := global_position + Vector3.UP * 1.0
	for light in get_tree().get_nodes_in_group("freeze_light"):
		var l := light as Light3D
		if l == null or not l.is_visible_in_tree():
			continue
		var reach := (l as OmniLight3D).omni_range if l is OmniLight3D else 6.0
		if l.global_position.distance_to(chest) <= reach and _clear_line(l.global_position, chest):
			return true
	return false


func _clear_line(from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	if _player:
		q.exclude.append(_player.get_rid())
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


# ---------- การเคลื่อนที่ ----------

## เดินไปที่ pos คืน true เมื่อถึงแล้ว
func _move_to(pos: Vector3, speed: float, delta: float) -> bool:
	if NavigationServer3D.map_get_iteration_id(_agent.get_navigation_map()) == 0:
		return false
	if _agent.target_position.distance_to(pos) > 0.3:
		_agent.target_position = pos
	if _agent.is_navigation_finished():
		_stop()
		return true
	var next := _agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	var slow := 1.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		var want := atan2(-dir.x, -dir.z)
		var err := absf(wrapf(want - rotation.y, -PI, PI))
		rotation.y = rotate_toward(rotation.y, want, profile.turn_speed * delta)
		# เลี้ยวแรงต้องชะลอก่อน (คนไม่หมุนตัวเต็มสปีด) · เดินไปทางที่หันอยู่เสมอ เท้าจะไม่ไถลข้าง
		slow = clampf(1.0 - err / (PI * 0.6), 0.25, 1.0)
	var fwd := -global_basis.z
	fwd.y = 0.0
	_cmd = speed
	_accelerate_to(fwd.normalized() * speed * slow, delta)
	move_and_slide()
	return false


func _stop() -> void:
	_cmd = 0.0
	_accelerate_to(Vector3.ZERO, _dt)
	move_and_slide()


## เร่งหรือชะลอความเร็วแนวราบเข้าหาเป้าแบบค่อยเป็นค่อยไป (ไม่เปลี่ยนทันที)
func _accelerate_to(target: Vector3, delta: float, decel_override := -1.0) -> void:
	var cur := Vector2(velocity.x, velocity.z)
	var tgt := Vector2(target.x, target.z)
	var rate := profile.accel if tgt.length() > cur.length() else profile.decel
	if decel_override > 0.0 and tgt.length() < cur.length():
		rate = decel_override
	cur = cur.move_toward(tgt, rate * delta)
	velocity.x = cur.x
	velocity.z = cur.y


func _random_point_near(center: Vector3) -> Vector3:
	var offset := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(1.0, profile.search_radius)
	return NavigationServer3D.map_get_closest_point(_agent.get_navigation_map(), center + offset)


func _start_search() -> void:
	_search_left = profile.search_time
	_set_state(State.SEARCH)


func _try_catch() -> void:
	if _player and global_position.distance_to(_player.global_position) < profile.catch_range:
		_set_state(State.CATCH)
		velocity = Vector3.ZERO
		_player.get_caught(self)


func _set_state(s: State) -> void:
	if s == state:
		return
	state = s
	awareness = {State.IDLE: 0.0, State.PATROL: 0.0, State.INVESTIGATE: 0.5, State.SEARCH: 0.6,
		State.CHASE: 1.0, State.FROZEN: 0.8, State.CATCH: 1.0}[s]
	state_changed.emit(s)


# ---------- ท่า ----------

func _update_anim(delta: float) -> void:
	if _anim == null:
		return
	# ความเร็วที่ใช้เลือกท่า ผ่านตัวกรองให้นุ่ม ท่าจะไม่สลับถี่ตามความเร็วที่แกว่งนิด ๆ
	var sp := Vector2(velocity.x, velocity.z).length()
	_hspeed = lerpf(_hspeed, sp, 1.0 - exp(-8.0 * delta))
	_moving = _hspeed > (0.1 if _moving else 0.25)
	# เลือกท่าจากความเร็วที่ "สั่งไว้ตามสถานะ" (กรองให้ค่อยเปลี่ยน) ไม่ใช่ความเร็วจริงที่แกว่งตอนเลี้ยว ท่าจะไม่สลับถี่
	_cmd_f = lerpf(_cmd_f, _cmd, 1.0 - exp(-4.0 * delta))
	var clip := _clip_cur
	var target_rate := 1.0
	if state == State.CATCH and profile.anim_catch != "":
		clip = profile.anim_catch
	elif state == State.FROZEN:
		target_rate = 0.0
	elif not _moving:
		clip = profile.anim_idle
	else:
		clip = _pick_move_clip(_cmd_f if _cmd_f > 0.2 else _hspeed)
		target_rate = clampf(_hspeed / _clip_speed(clip), 0.7, 1.5)
	# ความเร็วท่าเปลี่ยนแบบค่อยเป็นค่อยไป ไม่กระตุกทุกเฟรม
	_rate_cur = lerpf(_rate_cur, target_rate, 1.0 - exp(-10.0 * delta))
	if clip != "" and clip != _clip_cur and _anim.has_animation(clip):
		_anim.play(clip, 0.3)
		_clip_cur = clip
	_anim.speed_scale = _rate_cur


## ท่าเดิน/วิ่ง/วิ่งเร็ว ที่ความเร็วใกล้กับความเร็วจริงที่สุด (เทียบเป็นอัตราส่วน) · ท่าเดิมต้องแย่กว่าอย่างชัดเจนถึงจะเปลี่ยน
func _pick_move_clip(speed: float) -> String:
	var best := ""
	var best_err := INF
	var cur_err := INF
	for pair in _move_clips():
		var err := absf(log(speed / pair[1]))
		if err < best_err:
			best_err = err
			best = pair[0]
		if pair[0] == _clip_cur:
			cur_err = err
	if cur_err <= best_err + 0.25:
		return _clip_cur
	return best


func _move_clips() -> Array:
	var out := []
	for pair in [[profile.anim_walk, profile.anim_walk_speed], [profile.anim_run, profile.anim_run_speed],
			[profile.anim_sprint, profile.anim_sprint_speed]]:
		if pair[0] != "" and _anim.has_animation(pair[0]):
			out.append(pair)
	return out


func _clip_speed(clip: String) -> float:
	for pair in _move_clips():
		if pair[0] == clip:
			return pair[1]
	return 1.0


func _setup_model() -> void:
	if model_tint.a > 0.0:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = model_tint
		mat.roughness = 0.85
		for mi in find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = mat
	if _anim and profile:
		for clip in [profile.anim_idle, profile.anim_walk, profile.anim_run, profile.anim_sprint]:
			if clip != "" and _anim.has_animation(clip):
				_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR


func _find_anim(n: Node) -> AnimationPlayer:
	if n == null:
		return null
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var a := _find_anim(c)
		if a:
			return a
	return null
