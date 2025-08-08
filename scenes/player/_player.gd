extends CharacterBody3D

@export var SPEED = 5.0;
@export var JUMP_VELOCITY = 4.5;
@export var PLAYER_ACCELERATION = 5.0;
@export var SENSITIVITY = 1000
@export var LERP_SPEED = 5
@export var MAX_STAMINA = 100;

@onready var currentStaminaState = STAMINA_STATES.FULL;
@onready var stamina = MAX_STAMINA;
@onready var staminaSpendStep = 1;
@onready var staminaRecoveryCoef = 0.002;
@onready var staminaRecoveryStep = MAX_STAMINA * staminaRecoveryCoef
@onready var currentState;
@onready var flashLight = $Flashlight

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

func _ready():
	$CanvasLayer/Control/StaminaHUD.max_value = MAX_STAMINA;
	pass;

func _physics_process(delta: float) -> void:
	$CanvasLayer/Control/BatteryHUD.value = flashLight.batteryChagre;
	_basicMovement(delta);
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
	$CanvasLayer/Control/StaminaHUD.value = stamina
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

func _handleInventory():
	pass
