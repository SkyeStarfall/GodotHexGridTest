extends Camera3D

var _is_rotating: bool = false

var _velocity: Vector3 = Vector3(0, 0, 0) # movement direction
var _speed: float = 1.0 # meters per second
var _boost: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	self.translate(_velocity * _speed * (int(_boost) * 9 + 1))


func _unhandled_input(event: InputEvent) -> void:
	# Rotation
	if event.is_action_pressed("camera_rotate"):
		_is_rotating = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_released("camera_rotate"):
		_is_rotating = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion and _is_rotating:
		self.rotation.x += event.screen_relative.y * -0.001
		
		if self.rotation.x < -PI/2:
			self.rotation.x = -PI/2
		elif self.rotation.x > PI/2:
			self.rotation.x = PI/2
		
		self.rotation.y += event.screen_relative.x * -0.001
	
	# Speed
	if event.is_action_pressed("camera_speed_increase"):
		_speed *= 1 + 1.0/6.0
	if event.is_action_pressed("camera_speed_decrease"):
		_speed /= 1 + 1.0/6.0
	
	if _speed > 10:
		_speed = 10
	if _speed < 0.01:
		_speed = 0.01
	
	# Movement
	if event.is_action_pressed("camera_forward"):
		_velocity += Vector3.FORWARD
	elif event.is_action_pressed("camera_left"):
		_velocity += Vector3.LEFT
	elif event.is_action_pressed("camera_back"):
		_velocity += Vector3.BACK
	elif event.is_action_pressed("camera_right"):
		_velocity += Vector3.RIGHT
	elif event.is_action_pressed("camera_up"):
		_velocity += Vector3.UP
	elif event.is_action_pressed("camera_down"):
		_velocity += Vector3.DOWN
	
	if event.is_action_released("camera_forward"):
		_velocity -= Vector3.FORWARD
	elif event.is_action_released("camera_left"):
		_velocity -= Vector3.LEFT
	elif event.is_action_released("camera_back"):
		_velocity -= Vector3.BACK
	elif event.is_action_released("camera_right"):
		_velocity -= Vector3.RIGHT
	elif event.is_action_released("camera_up"):
		_velocity -= Vector3.UP
	elif event.is_action_released("camera_down"):
		_velocity -= Vector3.DOWN
	
	if event.is_action_pressed("camera_speed_boost"):
		_boost = true
	elif event.is_action_released("camera_speed_boost"):
		_boost = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_is_rotating = false
		self._velocity = Vector3.ZERO
		_boost = false
