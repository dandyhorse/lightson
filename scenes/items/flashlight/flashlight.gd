extends SpotLight3D

@export var MAX_BATTERY_CAPACITY = 100;

@onready var currentFlashlightState = FLASHLIGHT_STATES.OFF;
@onready var flashLight = $".";
@onready var batteryChagre = MAX_BATTERY_CAPACITY; 
@onready var batterySpendCoef = 0.00015;
@onready var batterySpendStep = MAX_BATTERY_CAPACITY * batterySpendCoef;
@onready var focusMaxAngle = flashLight.spot_angle;
@onready var focusMinAngle = 10;
@onready var currentState;
@onready var reloadTimer = $ReloadTimer;
@onready var batteries = 1;

const FLASHLIGHT_STATES = {
	ON = 'on',
	OFF = 'off',
	RELOADING = 'reloading',
	EMPTY = 'empty'
}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_flashLightProcess(delta);

func _updateFlashLightState(flashlightState):
	currentFlashlightState = flashlightState;
	
func _switchFlashLight():
		if (currentFlashlightState == FLASHLIGHT_STATES.ON):
			_updateFlashLightState(FLASHLIGHT_STATES.OFF);
		else:
			_updateFlashLightState(FLASHLIGHT_STATES.ON)
			
func _handleFlashLightState():
	match currentFlashlightState:
		FLASHLIGHT_STATES.ON:
			flashLight.light_energy = 10.0;
		FLASHLIGHT_STATES.OFF:
			flashLight.light_energy = 0.0;
		FLASHLIGHT_STATES.RELOADING:
			flashLight.light_energy = 0.0;
			batteryChagre = 0;
	pass;

func _handleBatteryChange():
	if currentFlashlightState == FLASHLIGHT_STATES.ON:
		if (batteryChagre - batterySpendStep < 0):
			batteryChagre = 0;
			_updateFlashLightState(FLASHLIGHT_STATES.OFF)
		else:
			batteryChagre -= batterySpendStep;
	
func _flashLightProcess(_delta: float) -> void:
	# LOOK AT SCREEN
	var ray = _screenPointToRay();
	if (ray != Vector3()):
		flashLight.look_at(ray)

	_handleFlashLightState()
	_handleBatteryChange()
	
	if reloadTimer.is_stopped():
		if currentFlashlightState == FLASHLIGHT_STATES.RELOADING:
			batteryChagre = MAX_BATTERY_CAPACITY;
			_updateFlashLightState(FLASHLIGHT_STATES.OFF)
		# ENABLE / DISABLE FL
		if Input.is_action_just_pressed("flashLight"):
			_switchFlashLight()
		# FOCUSING FL (configurable)
		if Input.is_action_just_pressed("focusFL"):
			if (flashLight.spot_angle > focusMinAngle):
				flashLight.spot_range += 2
				flashLight.spot_attenuation -= 0.2
				flashLight.spot_angle -= 5
		if Input.is_action_just_pressed("unfocusFL"):
			if (flashLight.spot_angle < focusMaxAngle):
				flashLight.spot_range -= 2
				flashLight.spot_attenuation += 0.2
				flashLight.spot_angle += 5
		if Input.is_action_just_pressed("reload"):
			if (batteries > 0):
				batteries -= 1
				reloadTimer.start()
				_updateFlashLightState(FLASHLIGHT_STATES.RELOADING)
			else:
				print("NOT ENOUGH BATTERIES")
	pass;

func _screenPointToRay():
	var spaceState = get_world_3d().direct_space_state;
	var mousePosition = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera_3d()
	var rayOrigin = camera.project_ray_origin(mousePosition)
	var rayEnd = rayOrigin + camera.project_ray_normal(mousePosition) * 2000;
	var parameters = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd)
	parameters.collision_mask = 2;
	var rayArray = spaceState.intersect_ray(parameters)
	if rayArray.has('position'):
		return rayArray['position']
	return Vector3();
