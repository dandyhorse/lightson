extends SpotLight3D

# Константы и перечисления
enum FlashlightState { ON, OFF, RELOADING, EMPTY }
@export var MAX_BATTERY_CAPACITY: float = 100.0
@export var BATTERY_SPEND_RATE: float = 0.95  # Заряд в секунду
@export var FOCUS_MIN_ANGLE: float = 10.0
@export var FOCUS_MAX_ANGLE: float = 60.0
@export var RELOAD_TIME: float = 2.0

# Ноды и переменные
@onready var flashlight: SpotLight3D = self
@onready var reload_timer: Timer = $ReloadTimer
@onready var battery_charge: float = MAX_BATTERY_CAPACITY
@onready var batteries: int = 1
var current_state: FlashlightState = FlashlightState.OFF

func _ready() -> void:
	reload_timer.wait_time = RELOAD_TIME
	reload_timer.one_shot = true  # Убедимся, что таймер однократный
	if not reload_timer.is_connected("timeout", _on_ReloadTimer_timeout):
		reload_timer.connect("timeout", _on_ReloadTimer_timeout)
	update_flashlight()

func _physics_process(delta: float) -> void:
	process_flashlight(delta)

func process_flashlight(delta: float) -> void:
	# Обработка направления фонарика
	if current_state == FlashlightState.ON:
		var ray = get_screen_point_to_ray()
		if ray != Vector3.ZERO:
			var target_rotation = flashlight.global_transform.looking_at(ray, Vector3.UP).basis
			flashlight.global_transform.basis = flashlight.global_transform.basis.slerp(target_rotation, 0.6)
	# Обработка состояния и батареи
	update_flashlight()
	handle_battery(delta)

	# Входы игрока
	if Input.is_action_just_pressed("flashLight"):
		toggle_flashlight()
	if Input.is_action_just_pressed("focusFL"):
		adjust_focus(-5.0, 2.0, -0.2)
	if Input.is_action_just_pressed("unfocusFL"):
		adjust_focus(5.0, -2.0, 0.2)
	if Input.is_action_just_pressed("reload") and reload_timer.is_stopped():
		start_reload()

func toggle_flashlight() -> void:
	if current_state == FlashlightState.ON:
		current_state = FlashlightState.OFF
	elif current_state == FlashlightState.OFF and battery_charge > 0:
		current_state = FlashlightState.ON
	update_flashlight()

func update_flashlight() -> void:
	match current_state:
		FlashlightState.ON:
			flashlight.light_energy = 10.0
		FlashlightState.OFF, FlashlightState.RELOADING, FlashlightState.EMPTY:
			flashlight.light_energy = 0.0

func handle_battery(delta: float) -> void:
	if current_state == FlashlightState.ON:
		battery_charge = max(0, battery_charge - BATTERY_SPEND_RATE * delta)
		if battery_charge <= 0 and current_state != FlashlightState.RELOADING:
			current_state = FlashlightState.EMPTY
			update_flashlight()

func start_reload() -> void:
	if batteries > 0:
		batteries -= 1
		current_state = FlashlightState.RELOADING
		battery_charge = 0.0  # Обнуляем заряд батареи при начале перезарядки
		reload_timer.start()
		update_flashlight()
	else:
		print("Not enough batteries!")  # TODO: Показать игроку уведомление

func adjust_focus(angle_change: float, range_change: float, attenuation_change: float) -> void:
	var new_angle = clamp(flashlight.spot_angle + angle_change, FOCUS_MIN_ANGLE, FOCUS_MAX_ANGLE)
	flashlight.spot_angle = new_angle
	flashlight.spot_range = clamp(flashlight.spot_range + range_change, 2.0, 20.0)
	flashlight.spot_attenuation = clamp(flashlight.spot_attenuation + attenuation_change, 0.1, 2.0)

func get_screen_point_to_ray() -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera_3d()
	if not camera:
		return Vector3.ZERO
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 2000.0
	var parameters = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	parameters.collision_mask = 2
	var ray_result = space_state.intersect_ray(parameters)
	return ray_result.get("position", Vector3.ZERO)

func _on_ReloadTimer_timeout() -> void:
	if current_state == FlashlightState.RELOADING:
		battery_charge = MAX_BATTERY_CAPACITY  # Восстанавливаем заряд батареи
		current_state = FlashlightState.OFF
		update_flashlight()
