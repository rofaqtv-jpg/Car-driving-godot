extends Node
class_name GameManager

# أنماط اللعب
enum GameMode { FREE_DRIVE, MOUNTAIN_CLIMB, OFF_ROAD, CHECKPOINT, MULTIPLAYER, VEHICLE_TEST }

var current_mode: GameMode = GameMode.FREE_DRIVE
var is_paused: bool = false
var checkpoint_index: int = 0
var checkpoints: Array[Vector3] = []
var lap_time: float = 0.0
var best_time: float = 0.0

# إحصائيات اللاعب
var total_distance: float = 0.0
var max_speed_reached: float = 0.0
var flips_count: int = 0
var crashes_count: int = 0

signal game_started(mode: GameMode)
signal checkpoint_reached(index: int)
signal game_completed(time: float)

func _ready() -> void:
    # تحميل الحفظ
    load_save_data()
    print("🎮 مدير اللعبة جاهز")

func start_game(mode: GameMode) -> void:
    current_mode = mode
    is_paused = false
    checkpoint_index = 0
    lap_time = 0.0
    
    match mode:
        GameMode.FREE_DRIVE:
            print("🏔️ قيادة حرة")
        GameMode.MOUNTAIN_CLIMB:
            print("⛰️ تسلق الجبل")
            setup_checkpoints()
        GameMode.OFF_ROAD:
            print("🏜️ تحدي الطرق الوعرة")
        GameMode.CHECKPOINT:
            print("🚩 تحدي نقاط التفتيش")
            setup_checkpoints()
        GameMode.VEHICLE_TEST:
            print("🧪 ساحة اختبار السيارة")
    
    game_started.emit(mode)

func setup_checkpoints() -> void:
    checkpoints = [
        Vector3(0, 0, -20),
        Vector3(10, 2, -40),
        Vector3(-5, 5, -60),
        Vector3(15, 8, -80),
        Vector3(0, 12, -100),  # القمة
    ]
    print("🚩 عدد نقاط التفتيش: ", checkpoints.size())

func _physics_process(delta: float) -> void:
    if not is_paused:
        lap_time += delta

func check_checkpoint(player_position: Vector3) -> void:
    if current_mode in [GameMode.MOUNTAIN_CLIMB, GameMode.CHECKPOINT]:
        if checkpoint_index < checkpoints.size():
            var cp := checkpoints[checkpoint_index]
            if player_position.distance_to(cp) < 5.0:
                checkpoint_index += 1
                checkpoint_reached.emit(checkpoint_index)
                print("✅ نقطة تفتيش ", checkpoint_index, "/", checkpoints.size())
                
                if checkpoint_index >= checkpoints.size():
                    game_completed.emit(lap_time)
                    print("🏁 اكتمل السباق! الوقت: ", lap_time)

func pause_game() -> void:
    is_paused = true
    get_tree().paused = true

func resume_game() -> void:
    is_paused = false
    get_tree().paused = false

func save_game() -> void:
    var save_data := {
        "best_time": best_time,
        "total_distance": total_distance,
        "max_speed": max_speed_reached,
        "crashes": crashes_count
    }
    
    var file := FileAccess.open("user://save_data.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save_data))
        print("💾 تم حفظ البيانات")

func load_save_data() -> void:
    if FileAccess.file_exists("user://save_data.json"):
        var file := FileAccess.open("user://save_data.json", FileAccess.READ)
        if file:
            var data := JSON.parse_string(file.get_as_text())
            if data:
                best_time = data.get("best_time", 0.0)
                total_distance = data.get("total_distance", 0.0)
                max_speed_reached = data.get("max_speed", 0.0)
                crashes_count = data.get("crashes", 0)
                print("📂 تم تحميل البيانات المحفوظة")
