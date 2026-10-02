extends Node3D
class_name VehicleCamera

@export var target: Node3D
@export var distance: float = 8.0
@export var height: float = 3.0
@export var smooth_speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var min_distance: float = 3.0
@export var max_distance: float = 20.0

var camera_mode: int = 0  # 0=خلفية, 1=قمرة, 2=علوية
var orbit_angle: float = 0.0
var orbit_height: float = 0.0
var is_orbiting: bool = false
var last_touch_position: Vector2 = Vector2.ZERO

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
    if not camera:
        camera = Camera3D.new()
        add_child(camera)
    camera.current = true
    camera.fov = 70.0

func _physics_process(delta: float) -> void:
    if not target:
        return
    
    match camera_mode:
        0: follow_behind(delta)
        1: cockpit_view(delta)
        2: top_down_view(delta)

func follow_behind(delta: float) -> void:
    var target_pos := target.global_position
    var target_forward := -target.global_transform.basis.z
    
    var desired_pos := target_pos - target_forward * distance + Vector3.UP * height
    
    # تدوير سلس
    if is_orbiting:
        var orbit_offset := Vector3(
            sin(orbit_angle) * distance,
            orbit_height,
            cos(orbit_angle) * distance
        )
        desired_pos = target_pos + orbit_offset
    
    camera.global_position = camera.global_position.lerp(desired_pos, smooth_speed * delta)
    
    # النظر إلى السيارة
    var look_target := target_pos + Vector3.UP * 1.0
    camera.look_at(look_target, Vector3.UP)

func cockpit_view(delta: float) -> void:
    var cockpit_pos := target.global_position + Vector3.UP * 1.2
    var forward := -target.global_transform.basis.z
    
    camera.global_position = camera.global_position.lerp(cockpit_pos, 10.0 * delta)
    camera.look_at(cockpit_pos + forward * 10.0, Vector3.UP)

func top_down_view(delta: float) -> void:
    var top_pos := target.global_position + Vector3.UP * 15.0
    camera.global_position = camera.global_position.lerp(top_pos, smooth_speed * delta)
    camera.look_at(target.global_position, Vector3.UP)

func switch_camera() -> void:
    camera_mode = (camera_mode + 1) % 3
    print("📷 الكاميرا: ", ["خلفية", "قمرة القيادة", "علوية"][camera_mode])

func _unhandled_input(event: InputEvent) -> void:
    # تدوير الكاميرا باللمس
    if event is InputEventScreenTouch:
        if event.pressed:
            is_orbiting = true
            last_touch_position = event.position
        else:
            is_orbiting = false
    
    if event is InputEventScreenDrag and is_orbiting:
        var delta_pos := event.position - last_touch_position
        orbit_angle += delta_pos.x * 0.01
        orbit_height = clampf(orbit_height + delta_pos.y * 0.01, -2.0, 5.0)
        last_touch_position = event.position
    
    # تقريب/إبعاد
    if event is InputEventMagnifyGesture:
        distance = clampf(distance / event.factor, min_distance, max_distance)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("switch_camera"):
        switch_camera()
