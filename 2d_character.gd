extends CharacterBody3D

@export var SPEED = 5.0;
@export var JUMP_VELOCITY = 4.5;
@export var PLAYER_ACCELERATION = 5.0;
@export var SENSITIVITY = 1000
@export var LERP_SPEED = 5

@onready var flashLight = $FlashLight;
@onready var isFlashLightEnabled = true;
@onready var focusMaxAngle = flashLight.spot_angle;
@onready var focusMinAngle = 5;
@onready var stamina = 100;
@onready var currentState;
@onready var currentStaminaState = STAMINA_STATES.FULL;

# ROADMAP
# realistic light from flashlight (semi done)
# state_machine
# inventory and item selection (!)
# running & climbing


const STATES = {
	DROP = 'drop',
	IDLE = 'idle',
	WALK = 'walk',
	RUN = 'run',
	CROUCH = 'crouch',
}

const STAMINA_STATES = {
	SPENDING = 'spending',
	RECOVERING = 'recovering',
	FULL = 'full',
	EMPTY = 'empty',
}

const FLASHLIGHT_STATES = {
	FLASHLIGHT_ON = 'flashlight_on',
	FLASHLIGHT_OFF = 'flashlight_off',
} 

func _physics_process(delta: float) -> void:
	_basicMovement(delta);
	_flashLightProcess(delta);
pass;

func setStaminaState(staminaState):
	if stamina == 100:
		currentStaminaState = STAMINA_STATES.FULL
	if stamina == 0:
		currentStaminaState = STAMINA_STATES.EMPTY
		
	match staminaState:
		STAMINA_STATES.EMPTY:
			currentStaminaState = STAMINA_STATES.EMPTY;
		STAMINA_STATES.FULL:
			currentStaminaState = STAMINA_STATES.FULL
		STAMINA_STATES.SPENDING:
			if stamina >= 0 && currentStaminaState != STAMINA_STATES.RECOVERING:
				$StaminaStateLabel.text = str(currentStaminaState) + " " + str(stamina)
				currentStaminaState = STAMINA_STATES.SPENDING
				stamina -= 1
				return true;
			else:
				setStaminaState(STAMINA_STATES.EMPTY)
				return false;
		STAMINA_STATES.RECOVERING:
			if (stamina <= 100):
				$StaminaStateLabel.text = str(currentStaminaState) + " " + str(stamina)
				currentStaminaState = STAMINA_STATES.RECOVERING;
				stamina += 1;
			else:
				currentStaminaState = STAMINA_STATES.FULL

func setState(state) -> void:
	currentState = state;
	$SpeedLabel.text = str(SPEED);
	
	match state:
		STATES.DROP:
			$StateLabel.text = 'DROP'
			pass;
		STATES.IDLE:
			$StateLabel.text = 'IDLE'
			if (currentStaminaState != STAMINA_STATES.FULL):
				setStaminaState(STAMINA_STATES.RECOVERING)
		STATES.WALK:
			$StateLabel.text = 'WALK'
			SPEED = 5.0
			if (currentStaminaState != STAMINA_STATES.FULL):
				setStaminaState(STAMINA_STATES.RECOVERING)
		STATES.RUN:
			if setStaminaState(STAMINA_STATES.SPENDING):
				$StateLabel.text = 'RUN'
				currentState = state;
				SPEED = 10.0;
			else:
				$StateLabel.text = 'TIRED'
				currentState = STATES.WALK;
				SPEED = 5.0;
		STATES.CROUCH:
			$StateLabel.text = 'CROUCH'
	pass;
	
func _basicMovement(delta: float) -> void:
	print(currentStaminaState)
	
	if not is_on_floor():
		setState(STATES.DROP)
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			if Input.is_action_pressed("run"):
				setState(STATES.RUN)
			else:
				setState(STATES.WALK)
			var target_velocity := Vector3(direction.x * SPEED, velocity.y, direction.z * SPEED)
			velocity.x = lerp(velocity.x, target_velocity.x, LERP_SPEED * delta)
			velocity.z = lerp(velocity.z, target_velocity.z, LERP_SPEED * delta)
		else:
			setState(STATES.IDLE)
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if Input.is_action_pressed("crouch"):
			setState(STATES.CROUCH)

	move_and_slide()
	pass;

func _flashLightProcess(delta: float) -> void:
	var ray = ScreenPointToRay();
	
	if (ray != Vector3()):
		#not working, idk why
		#var lookAtRay = lerp(flashLight.global_position, ray, delta * 0.1)
		flashLight.look_at(ray)

	# ENABLE / DISABLE FL
	if Input.is_action_just_pressed("flashLight"):
		if (isFlashLightEnabled):
			isFlashLightEnabled = false;
			flashLight.light_energy = 0.0;
		else: 
			isFlashLightEnabled = true;
			flashLight.light_energy = 10.0;

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
	pass;

func ScreenPointToRay():
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
