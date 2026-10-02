extends Node3D
class_name VehicleController

# ============================================================
# قمة الصعود | نظام فيزياء المركبة
# ============================================================

# المحرك
@export var engine_power: float = 300.0
@export var max_engine_rpm: float = 7000.0
@export var idle_rpm: float = 800.0
@export var brake_force: float = 50.0
@export var reverse_power: float = 150.0

# ناقل الحركة
@export var gear_ratios: Array[float] = [0.0, 3.5, 2.5, 1.8, 1.3, 1.0, 0.8]
@export var final_drive_ratio: float = 3.7
@export var shift_up_rpm: float = 6000.0
@export var shift_down_rpm: float = 2500.0
var current_gear: int = 1

# التعليق
@export var suspension_stiffness: float = 55.0
@export var suspension_travel: float = 0.3
@export var suspension_damping: float = 4.5
@export var wheel_radius: float = 0.35

# التوجيه
@export var max_steer_angle: float = 30.0
@export var steer_speed: float = 3.0

# الحالة
var speed: float = 0.0
var engine_rpm: float = 800.0
var velocity: Vector3 = Vector3.ZERO
var steer_input: float = 0.0
var throttle_input: float = 0.0
var brake_input: float = 0.0
var handbrake_input: bool = false
var is_grounded: bool = true
var damage_level: float = 0.0

# العجلات
@onready var wheels: Array[Node3D] = []
@onready var wheel_raycasts: Array[RayCast3D] = []
@onready var chassis: RigidBody3D = $Chassis

# الإشارات
signal speed_changed(new_speed: float)
signal gear_changed(new_gear: int)
signal damaged(amount: float)

func _ready() -> void:
    # جمع العجلات
    for child in get_children():
        if child is Node3D and child.name.begins_with("Wheel"):
            wheels.append(child)
            # إضافة RayCast لكل عجلة
            var ray = RayCast3D.new()
            ray.target_position = Vector3(0, -suspension_travel - wheel_radius, 0)
            ray.enabled = true
            child.add_child(ray)
            wheel_raycasts.append(ray)
    
    print("🚗 نظام المركبة جاهز | قوة المحرك: ", engine_power)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(chassis):
        return
    
    # 1. قراءة المدخلات
    read_inputs()
    
    # 2. حساب التوجيه
    update_steering(delta)
    
    # 3. حساب قوة المحرك
    var engine_force := calculate_engine_force()
    
    # 4. تطبيق القوى على العجلات
    apply_wheel_forces(engine_force, delta)
    
    # 5. تحديث التعليق
    update_suspension(delta)
    
    # 6. تحديث السرعة
    speed = chassis.linear_velocity.length()
    engine_rpm = calculate_rpm()
    
    # 7. ناقل الحركة التلقائي
    update_transmission()
    
    # 8. إرسال الإشارات
    speed_changed.emit(speed * 3.6)  # تحويل إلى km/h

func read_inputs() -> void:
    throttle_input = Input.get_action_strength("accelerate")
    brake_input = Input.get_action_strength("brake")
    steer_input = Input.get_axis("steer_left", "steer_right")
    handbrake_input = Input.is_action_pressed("handbrake")

func update_steering(delta: float) -> void:
    # تقليل زاوية التوجيه عند السرعات العالية
    var speed_factor := clampf(1.0 - speed / 40.0, 0.3, 1.0)
    var target_steer := steer_input * max_steer_angle * speed_factor
    
    # تطبيق التوجيه على العجلات الأمامية
    for i in range(mini(2, wheels.size())):
        if wheels[i]:
            wheels[i].rotation.y = deg_to_rad(target_steer)

func calculate_engine_force() -> float:
    var force := 0.0
    
    if throttle_input > 0:
        # منحنى عزم واقعي
        var rpm_factor := engine_rpm / max_engine_rpm
        var torque_curve := sin(rpm_factor * PI) * engine_power
        force = throttle_input * torque_curve * gear_ratios[current_gear] * final_drive_ratio
    
    if brake_input > 0:
        if speed > 1.0:
            force = -brake_input * brake_force
        else:
            force = -brake_input * reverse_power
    
    if handbrake_input:
        force *= 0.1  # تقليل القوة مع فرامل اليد
    
    # تقليل القوة بسبب التلف
    force *= (1.0 - damage_level * 0.005)
    
    return force

func apply_wheel_forces(force: float, delta: float) -> void:
    if not is_grounded:
        return
    
    var forward := -chassis.global_transform.basis.z
    
    # تطبيق القوة على مركز الكتلة
    chassis.apply_central_force(forward * force)
    
    # قوة التوجيه
    if absf(steer_input) > 0.1 and speed > 0.5:
        var steer_force := chassis.global_transform.basis.x * steer_input * speed * 2.0
        chassis.apply_central_force(steer_force)
    
    # فرامل يدوية - انجراف
    if handbrake_input:
        chassis.angular_velocity.y *= 0.95

func update_suspension(delta: float) -> void:
    var grounded_count := 0
    
    for i in range(wheel_raycasts.size()):
        var ray := wheel_raycasts[i]
        if ray and ray.is_colliding():
            grounded_count += 1
            var collision_point := ray.get_collision_point()
            var distance := chassis.global_position.distance_to(collision_point)
            
            # قوة النابض
            var compression := suspension_travel - (distance - wheel_radius)
            if compression > 0:
                var spring_force := compression * suspension_stiffness * 100.0
                var up := chassis.global_transform.basis.y
                chassis.apply_force(up * spring_force, wheels[i].global_position)
    
    is_grounded = grounded_count >= 3

func calculate_rpm() -> float:
    var wheel_circumference := 2.0 * PI * wheel_radius
    var wheel_rpm := (speed / wheel_circumference) * 60.0
    var engine := wheel_rpm * gear_ratios[current_gear] * final_drive_ratio
    return clampf(engine, idle_rpm, max_engine_rpm)

func update_transmission() -> void:
    if engine_rpm > shift_up_rpm and current_gear < gear_ratios.size() - 1:
        current_gear += 1
        gear_changed.emit(current_gear)
    elif engine_rpm < shift_down_rpm and current_gear > 1:
        current_gear -= 1
        gear_changed.emit(current_gear)

func apply_damage(amount: float) -> void:
    damage_level = minf(damage_level + amount, 100.0)
    damaged.emit(damage_level)
    
    if damage_level >= 100.0:
        engine_power *= 0.3  # محرك معطل
        print("💥 السيارة معطلة!")

func repair() -> void:
    damage_level = 0.0
    engine_power = 300.0
    print("🔧 تم إصلاح السيارة")

func reset_vehicle() -> void:
    chassis.global_position = Vector3(0, 3, 0)
    chassis.linear_velocity = Vector3.ZERO
    chassis.angular_velocity = Vector3.ZERO
    chassis.rotation = Vector3.ZERO
    current_gear = 1
    print("↺ إعادة تعيين السيارة")
