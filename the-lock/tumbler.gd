class_name Tumbler extends Node3D

enum TumblerState {IDLE,RISING,PICKABLE,FALLING,SET}

var spring_min_size:float = 0.1

@export_category("References")
@export var spring:Node3D
@export var tumbler:Node3D
@export var tumbler_target:Node3D

# how fast the tumblers move up when picked
var _min_raise_time:float
var _max_raise_time:float
var _min_pickable_time:float
var _max_pickable_time:float
var _min_falling_time:float
var _max_falling_time:float

var _state:TumblerState = TumblerState.IDLE
var _timer:float = 0.0 # timer used for all state transitions
var _target:float = 0.0 # target time used for all state transitions
var _target_size:Vector3

func _physics_process(delta: float) -> void:
	tumbler.global_position = tumbler_target.global_position
	
	match _state:
		TumblerState.RISING:
			var step:float = remap(_timer,0,_target,0,1)
			spring.scale = lerp(Vector3.ONE,_target_size,step)
			_timer += delta
		
			if _timer > _target:
				_timer = 0
				_target = randf_range(_min_pickable_time,_max_pickable_time)
				spring.scale = _target_size
				_state = TumblerState.PICKABLE
		TumblerState.PICKABLE:
			_timer += delta
			if _timer > _target:
				_timer = 0
				_target = randf_range(_min_falling_time,_max_falling_time)
				_state = TumblerState.FALLING
		TumblerState.FALLING:
			var step:float = remap(_timer, 0, _target, 0, 1)
			spring.scale = lerp(_target_size, Vector3.ONE, step)
			_timer += delta
			if _timer > _target:
				_timer = 0
				_target = randf_range(_min_raise_time,_max_raise_time)
				spring.scale = Vector3.ONE
				_state = TumblerState.IDLE

func initialize(min_raise:float,max_raise:float,min_pickable:float,max_pickable:float,min_fall:float,max_fall:float)->void:
	_target_size = Vector3(1,spring_min_size,1)
	_min_raise_time = min_raise
	_max_raise_time = max_raise
	_min_pickable_time = min_pickable
	_max_pickable_time = max_pickable
	_min_falling_time = min_fall
	_max_falling_time = max_fall
	reset()

func knock_tumbler()->void:
	if _state != TumblerState.IDLE:
		return
	_state = TumblerState.RISING

func get_tumbler_state()->TumblerState:
	return _state

func reset()->void:
	_state = TumblerState.IDLE
	spring.scale = Vector3.ONE
	_target = randf_range(_min_raise_time,_max_raise_time)

func set_state()->void:
	_state = TumblerState.SET
