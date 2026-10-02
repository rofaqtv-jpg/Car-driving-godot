extends CanvasLayer
class_name TouchControls

# أزرار التحكم
@onready var gas_button: TouchScreenButton = $Controls/GasButton
@onready var brake_button: TouchScreenButton = $Controls/BrakeButton
@onready var left_button: TouchScreenButton = $Controls/LeftButton
@onready var right_button: TouchScreenButton = $Controls/RightButton
@onready var handbrake_button: TouchScreenButton = $Controls/HandbrakeButton

func _ready() -> void:
    # ربط إشارات الأزرار
    if gas_button:
        gas_button.pressed.connect(_on_gas_pressed)
        gas_button.released.connect(_on_gas_released)
    
    if brake_button:
        brake_button.pressed.connect(_on_brake_pressed)
        brake_button.released.connect(_on_brake_released)
    
    if left_button:
        left_button.pressed.connect(_on_left_pressed)
        left_button.released.connect(_on_left_released)
    
    if right_button:
        right_button.pressed.connect(_on_right_pressed)
        right_button.released.connect(_on_right_released)
    
    if handbrake_button:
        handbrake_button.pressed.connect(_on_handbrake_pressed)
        handbrake_button.released.connect(_on_handbrake_released)
    
    print("🎮 أزرار التحكم جاهزة")

func _on_gas_pressed() -> void:
    Input.action_press("accelerate")

func _on_gas_released() -> void:
    Input.action_release("accelerate")

func _on_brake_pressed() -> void:
    Input.action_press("brake")

func _on_brake_released() -> void:
    Input.action_release("brake")

func _on_left_pressed() -> void:
    Input.action_press("steer_left")

func _on_left_released() -> void:
    Input.action_release("steer_left")

func _on_right_pressed() -> void:
    Input.action_press("steer_right")

func _on_right_released() -> void:
    Input.action_release("steer_right")

func _on_handbrake_pressed() -> void:
    Input.action_press("handbrake")

func _on_handbrake_released() -> void:
    Input.action_release("handbrake")
