# code qui fonctionne parfaitement:
extends CharacterBody2D
class_name PlayerController
@export var speed: float = 15.0
@export var jump_power=27
@onready var body=$Player/Body

@export var gravity_up: float = 2000    # Pendant la montée 
@export var gravity_down: float = 3000  # Pendant la descente (plus rapide que la montée)

@export var dash_upward_limit = 1000.0

var dash_object = load("res://Assets/Script/dash_sprite.tscn")
@export var dash_length=0.2
@export var dash_speed= 2000

@onready var dash_timer = $dash/dash_timer
@onready var dash_particles = $dash/dash_particles
@onready var dash_cooldown_timer = $DashCooldownTimer

var is_dashing : bool = false
var can_dash : bool = true
var dash_direction : Vector2

var vSpeed = 0
var hSpeed = 0

var touching_ground: bool = false
var touching_wall: bool = false
var speed_multiplier: float = 40.0
@onready var jump_multiplier = -43.0
var direction = 0
var touch_is_pressed = false




func jump():
	velocity.y=jump_power * jump_multiplier
	
func jump_side(x):
	#velocity.y = jump_power * jump_multiplier
	#velocity.x = x * speed_multiplier * speed
	velocity = Vector2(x *speed *speed_multiplier, jump_power*jump_multiplier)



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dash_cooldown_over := true

var Animation_pl
@onready var animation_player=$Player/AnimationPlayer



func _ready():
	
	velocity = Vector2.ZERO
	initialize_player()
	dash_timer.timeout.connect(dash_timer_timeout)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)

func dash_timer_timeout():
	is_dashing = false

func _on_dash_cooldown_timeout():
	dash_cooldown_over = true

func is_controller():
	if(Input.get_action_strength("down") > 0.7):
		return true
	if(Input.get_action_strength("jump") > 0.7):
		return true
	if(Input.get_action_strength("right") > 0.7):
		return true
	if(Input.get_action_strength("left") > 0.7):
		return true
	if(Input.get_action_strength("ui_up") > 0.7):
		return true
	return false
	
func get_direction_from_input():
	var move_dir = Vector2()
	var controller = is_controller()
	print(controller)
	if(controller):
		move_dir.x = -Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right")
		#move_dir.y = -Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	else:
		move_dir.x = -Input.get_action_strength("left") + Input.get_action_strength("right")
		#move_dir.y = -Input.get_action_strength("jump") + Input.get_action_strength("down")
	move_dir = move_dir.limit_length(1)
	
	if (move_dir == Vector2(0,0)):
		if(body.flip_h):
			move_dir.x = -1
		else:
			move_dir.x = 1
	return move_dir * dash_speed
	
func handle_dash(delta):
	if(Input.is_action_just_pressed("dash") and can_dash):
		is_dashing = true
		can_dash = false
		dash_cooldown_over = false
		dash_direction = get_direction_from_input()
		dash_timer.start(dash_length)
		dash_cooldown_timer.start()
		
	if(is_dashing):
		var dash_node = dash_object.instantiate()
		dash_node.texture = body.texture
		dash_node.global_position = global_position
		dash_node.flip_h = body.flip_h
		dash_node.frame = body.frame
		get_parent().add_child(dash_node)

		dash_particles.emitting = true
		if(is_on_wall()):
			is_dashing = false
	else:
		dash_particles.emitting = false
		
func _touching_ground() -> bool:
	return is_on_floor()
	
func _touching_wall() -> bool:
	return is_on_wall()

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		touch_is_pressed = event.pressed



func _physics_process(delta):
		
	if is_on_floor() and dash_cooldown_over:
		can_dash = true
	#else:
		#can_dash = false

	handle_dash(delta)
	touching_wall = is_on_wall()
	touching_ground = is_on_floor()

	if is_dashing:
		velocity = dash_direction  # ignore la gravité
	else:
		# Gravité variable selon montée/descente
		if not is_on_floor():
			if velocity.y < 0:
				velocity.y += gravity_up * delta
			else:
				velocity.y += gravity_down * delta
		else:
			if Input.is_action_pressed("jump") or touch_is_pressed:
				velocity.y = jump_power * jump_multiplier

		# Mouvement horizontal normal
		direction = Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * speed * speed_multiplier
		else:
			velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)
	move_and_slide()

func initialize_player():
	body.texture = PlayerChoice.body_spritesheet[PlayerChoice.selected_body]



func _on_dash_pressed():
	Input.action_press("dash")
