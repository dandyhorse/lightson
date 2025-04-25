extends CharacterBody3D

@export var SPEED = 5.0;
@export var JUMP_VELOCITY = 4.5;
@export var PLAYER_ACCELERATION = 5.0;
@export var SENSITIVITY = 1000
@export var LERP_SPEED = 5
#@export var MAX_STAMINA = 100;
@export var MAX_BATTERY_CAPACITY = 100;

# FL
@onready var currentFlashlightState = FLASHLIGHT_STATES.OFF;
@onready var flashLight = $FlashLight;
@onready var batteryChagre = MAX_BATTERY_CAPACITY; 
@onready var batteryRecoveryCoef = 0.001;
@onready var batterySpendStep = MAX_BATTERY_CAPACITY * batteryRecoveryCoef;
@onready var focusMaxAngle = flashLight.spot_angle;
@onready var focusMinAngle = 10;
@onready var currentState;

#STAMINA
@onready var MAX_STAMINA = 200;
@onready var currentStaminaState = STAMINA_STATES.FULL;
@onready var stamina = MAX_STAMINA;
@onready var staminaSpendStep = 1;
@onready var staminaRecoveryCoef = 0.01;
@onready var staminaRecoveryStep = MAX_STAMINA * staminaRecoveryCoef

const STATES = {
	DROP = 'drop',
	IDLE = 'idle',
	WALK = 'walk',
	RUN = 'run',
	CROUCH = 'crouch',
}

const STAMINA_STATES = {
	FULL = 'full',
	EMPTY = 'empty',
	SPENDING = 'spending',
	RECOVERING = 'recovering',
}

const FLASHLIGHT_STATES = {
	ON = 'on',
	OFF = 'off',
	RELOADING = 'reloading'
} 

func _ready():
	$CanvasLayer/Control/ProgressBar.max_value = MAX_STAMINA;
	pass;

func _physics_process(delta: float) -> void:
	$CanvasLayer/Control/Battery.text = str(batteryChagre);
	_basicMovement(delta);
	_flashLightProcess(delta);
	_handleStaminaState();
	pass;

func _basicMovement(delta: float) -> void:
	if not is_on_floor():
		_updatePlayerState(STATES.DROP)
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("left", "right", "up", "down");
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			if Input.is_action_pressed("run"):
				_updatePlayerState(STATES.RUN)
			else:
				_updatePlayerState(STATES.WALK)
			var target_velocity := Vector3(direction.x * SPEED, velocity.y, direction.z * SPEED)
			velocity.x = lerp(velocity.x, target_velocity.x, LERP_SPEED * delta)
			velocity.z = lerp(velocity.z, target_velocity.z, LERP_SPEED * delta)
		else:
			_updatePlayerState(STATES.IDLE)
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
		if Input.is_action_pressed("crouch"):
			_updatePlayerState(STATES.CROUCH)

	move_and_slide()
	pass;

func _updatePlayerState(state) -> void:
	currentState = state;
	
	if (currentStaminaState != STAMINA_STATES.FULL):
		_updateStaminaState(STAMINA_STATES.RECOVERING);
	
	match state:
		STATES.DROP:
			$CanvasLayer/Control/PlayerState.text = 'DROP'
			pass;
		STATES.IDLE:
			$CanvasLayer/Control/PlayerState.text = 'IDLE'
			pass;
		STATES.WALK:
			$CanvasLayer/Control/PlayerState.text = 'WALK'
			SPEED = 5.0
			pass;
		STATES.RUN:
			_updateStaminaState(STAMINA_STATES.SPENDING)
			if stamina > 0:
				$CanvasLayer/Control/PlayerState.text = 'RUN'
				currentState = state;
				SPEED = 10.0;
			else: 
				$CanvasLayer/Control/PlayerState.text = 'TIRED'
				SPEED = 5.0;
				pass;
		#STATES.CROUCH:
			#$CanvasLayer/Control/PlayerState.text = 'CROUCH'
	pass;

func _handleStaminaState():
	$CanvasLayer/Control/ProgressBar.value = stamina
	
	match currentStaminaState:
		STAMINA_STATES.SPENDING:
			if stamina > 0:
				stamina -= staminaSpendStep
				if stamina < 0:
					stamina = 0
					currentStaminaState = STAMINA_STATES.EMPTY
			pass
		STAMINA_STATES.RECOVERING:
			if stamina < MAX_STAMINA:
				stamina += staminaRecoveryStep
				if stamina >= MAX_STAMINA:
					stamina = MAX_STAMINA
					currentStaminaState = STAMINA_STATES.FULL
			pass


func _updateStaminaState(staminaState):
	if stamina == MAX_STAMINA:
		currentStaminaState = STAMINA_STATES.FULL
		pass;
	if stamina == 0:
		currentStaminaState = STAMINA_STATES.EMPTY
		pass;
		
	currentStaminaState = staminaState;
	
	pass;

func _switchFlashLight():
	if (batteryChagre > 0):
		if (currentFlashlightState == FLASHLIGHT_STATES.ON):
			_updateFlashLightState(FLASHLIGHT_STATES.OFF);
		else:
			_updateFlashLightState(FLASHLIGHT_STATES.ON)
	else:
		print("NEED TO RELOAD FL")

func _updateFlashLightState(flashlightState):
	match flashlightState:
		FLASHLIGHT_STATES.ON:
			currentFlashlightState = FLASHLIGHT_STATES.ON;
		FLASHLIGHT_STATES.OFF:
			currentFlashlightState = FLASHLIGHT_STATES.OFF;
		

func _handleFlashLightState():
	match currentFlashlightState:
		FLASHLIGHT_STATES.ON:
			flashLight.light_energy = 10.0;
		FLASHLIGHT_STATES.OFF:
			flashLight.light_energy = 0.0;
		FLASHLIGHT_STATES.RELOADING:
			pass;
	pass;

func _handleBatteryChange():
	if currentFlashlightState == FLASHLIGHT_STATES.ON:
		if (batteryChagre - batterySpendStep < 0):
			batteryChagre = 0;
			_updateFlashLightState(FLASHLIGHT_STATES.OFF)
		else:
			batteryChagre -= batterySpendStep;

func _flashLightProcess(_delta: float) -> void:
	_handleFlashLightState()
	_handleBatteryChange()
	
	# LOOK AT SCREEN
	var ray = _screenPointToRay();
	if (ray != Vector3()):
		flashLight.look_at(ray)

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
		print("reload")
		pass;
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


# ROADMAP
# realistic light from flashlight (semi done)
# state_machine
# inventory and item selection (!)
# running & climbing
# reload of flashlight

#func _input(event):
	#if event is InputEventMouseMotion:
		#$CameraPivot.rotation.y -= event.relative.x / SENSITIVITY
		#$CameraPivot.rotation.x -= event.relative.y / SENSITIVITY
		#$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-10), deg_to_rad(5))
		#$CameraPivot.rotation.y = clamp($CameraPivot.rotation.y, deg_to_rad(-25), deg_to_rad(25))

#func rotate_towards(target_position: Vector3) -> void:
	#var direction = (target_position - global_transform.origin).normalized()
	#var target_rotation = direction.angle_to(Vector3.FORWARD)
	#var current_rotation = rotation.y
	#var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * get_process_delta_time())
	#rotation.y = new_rotation
