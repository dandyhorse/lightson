extends WorldEnvironment

@onready var sky_color_anim_player = $WorldEnvAnimationPlayer
@onready var light_anim_player = $"../SunMoonLight/LightAnimationPlayer"
@onready var sky_color_main_animation = "SkyColor"
@onready var light_main_animation = "Rotate"
@export var animation_speed_scale: float = 0.5  

enum DayPhase { MORNING, DAY, EVENING, NIGHT }
var current_phase: DayPhase = DayPhase.NIGHT

func _ready() -> void:
	sky_color_anim_player.speed_scale = animation_speed_scale
	light_anim_player.speed_scale = animation_speed_scale
	
	sky_color_anim_player.play(sky_color_main_animation)
	light_anim_player.play(light_main_animation)
	
	var sky_color_main_animation_full_length = sky_color_anim_player.current_animation_length / animation_speed_scale
	print("Full animation length: ", sky_color_main_animation_full_length, " seconds")

func _process(delta: float) -> void:
	var sky_color_main_animation_full_length = sky_color_anim_player.current_animation_length / animation_speed_scale
	var current_time = sky_color_anim_player.current_animation_position
	
	
	var new_phase: DayPhase
	if current_time < 1.5: 
		new_phase = DayPhase.DAY
	elif current_time < 3.0: 
		new_phase = DayPhase.EVENING
	elif current_time < 9.0:  
		new_phase = DayPhase.NIGHT
	elif current_time < 10.5:  
		new_phase = DayPhase.MORNING
	else:  
		new_phase = DayPhase.DAY

	if new_phase != current_phase:
		current_phase = new_phase
		match current_phase:
			DayPhase.MORNING:
				print("MORNING")
			DayPhase.DAY:
				print("DAY")
			DayPhase.EVENING:
				print("EVENING")
			DayPhase.NIGHT:
				print("NIGHT")
