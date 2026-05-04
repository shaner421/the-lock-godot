class_name Lock extends Node3D

signal on_lock_picked

@export_category("References")
@export var tumbler:PackedScene = preload("res://the-lock/tumbler.tscn")
@export var tumbler_origin:Node3D
@export var lockpick:Node3D
@export var lockpick_target:Node3D

@export_category("Lock Settings")
@export var lockpick_speed:float = 1.0 # how fast the lockpick moves on the X axis

@export var lockpick_base_height = -1.0 # Y height that the lockpick sits at
@export var lockpick_picking_height:float = 0.0 # Y height it goes to during picking

@export var picking_half_length:float = 0.5 # total time the lockpick spends moving up and down during a pick, split between an up and down motion, thus half-length
@export var number_of_tumblers_retained_on_failure:int = 0 # when failing to pick a tumbler, this amount will stay set, akin to higher thieving levels in TES4

@export_category("Tumbler Settings")
# basic tumbler settings
@export var number_of_tumblers:int # you can have any number of tumblers you want
@export var tumbler_spacing:float # physical x distance between tumblers

# how fast the tumblers move up when picked
@export var min_raise_time:float = 0.1
@export var max_raise_time:float = 0.5

# how long the tumblers stay up and in a pickable state
@export var min_pickable_time:float = 0.1
@export var max_pickable_time:float = 0.5

# how long it takes the tumblers to return to neutral
@export var min_falling_time:float = 0.1
@export var max_falling_time:float = 0.5

enum TumblerState {IDLE,RISING,PICKABLE,FALLING,SET}

var _tumblers:Array[Tumbler]
var _current_tumbler:int = 0

var _picking:bool = false
var _picking_timer:float = 0.0
var _rising:bool = true

var current_tumbler:Tumbler

func _ready() -> void:
	# basic initialization
	_tumblers = []
	for x in number_of_tumblers:
		var newTumbler:Tumbler = tumbler.instantiate()
		_tumblers.append(newTumbler)
		add_child(newTumbler)
		newTumbler.position = Vector3(tumbler_spacing * x, tumbler_origin.position.y, tumbler_origin.position.z)
		newTumbler.initialize(min_raise_time, max_raise_time, min_pickable_time, max_pickable_time, min_falling_time, max_falling_time)
	current_tumbler = _tumblers[_current_tumbler]
	
	lockpick_target.position = Vector3(current_tumbler.position.x,lockpick_base_height,0)
	lockpick.position = lockpick_target.position
	
func _physics_process(delta: float) -> void:
	
	# lockpick follows target with lerp for smooth movement
	lockpick.position = lerp(lockpick.position,lockpick_target.position,lockpick_speed * delta)
	
	# lockpick rising and descending controlled via code
	if _picking:
		_picking_timer += delta
		if _picking_timer > picking_half_length:
			_picking_timer = 0
			if _rising:
				_rising = false
				lockpick_target.position = Vector3(current_tumbler.position.x,lockpick_base_height,0)
			else:
				_rising = true
				_picking = false

# godot input instead of colin's unity stuff
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_left"):
		on_move_pick(-1)
	if Input.is_action_pressed("ui_right"):
		on_move_pick(1)
	if Input.is_action_pressed("ui_up"):
		on_hit_tumbler()
	if Input.is_action_pressed("ui_select"):
		on_try_pick()
	

func on_move_pick(dir:int)->void:
	if _picking:
		return
	
	# change index based on direction
	if dir > 0:
		_current_tumbler+=1
	else:
		_current_tumbler -=1
	
	# wraparound
	if _current_tumbler > _tumblers.size() -1:
		_current_tumbler = 0
	
	if _current_tumbler < 0:
		_current_tumbler = _tumblers.size() -1
	
	current_tumbler = _tumblers[_current_tumbler]
	lockpick_target.position = Vector3(current_tumbler.position.x,lockpick_base_height,0)

func on_hit_tumbler()->void:
	if _picking || current_tumbler.get_tumbler_state() == Tumbler.TumblerState.SET:
		return
	_picking = true
	current_tumbler.knock_tumbler()
	lockpick_target.position = Vector3(current_tumbler.position.x,lockpick_picking_height,0)


func on_try_pick()-> void:
	var state = _tumblers[_current_tumbler].get_tumbler_state()
	
	if state == TumblerState.IDLE || state == TumblerState.SET:
		return
	if state == TumblerState.PICKABLE:
		current_tumbler.set_state()
		
		# check if all tumblers are set
		for x in _tumblers:
			if x.get_tumbler_state() != TumblerState.SET:
				return
		on_lock_picked.emit()
		return
	
	# failure, time to break puzzle
	
	lockpick_target.position = Vector3(current_tumbler.position.x,lockpick_base_height,0)
	lockpick.position = lockpick_target.position
	
	var tumblers_skipped = 0
	_picking = false
	_rising = true
	
	for x in _tumblers:
		if tumblers_skipped < number_of_tumblers_retained_on_failure && x.get_tumbler_state() == TumblerState.SET:
			tumblers_skipped +=1
			continue
		x.reset()
		
	
