extends CanvasLayer

# ВАЖНО: Нажми правой кнопкой на узел PlayerAttack в дереве сцены, 
# выбери "Access as Unique Name" (появится значок %). 
# Тогда путь в коде можно будет сократить до %PlayerAttack.
@onready var player_attack_game = %PlayerAttack 
@onready var attack_button = $VBoxContainer/FunctionButtons/Attack
@onready var enemy_attack = %EnemyAttack_geometry_dash_style

var attack_running := false

func _ready():
	if enemy_attack:
		enemy_attack.finished.connect(_on_enemy_attack_finished)
	else:
		printerr("TEST!")
	
	if player_attack_game:
		player_attack_game.attack_finished.connect(_on_player_attack_finished)
	else:
		printerr("ОШИБКА: Мини-игра PlayerAttack не найдена в дереве!")

func test_enemy_attack():
	$VBoxContainer/FunctionButtons/Attack.disabled = true
	enemy_attack.start({ "damage": 12, "duration": 12.0 })
	
func _on_attack_pressed():
	if attack_running:
		return
	$VBoxContainer/FunctionButtons/Attack.disabled = true
	attack_button.release_focus()
	player_attack_game.start()

func _on_player_attack_finished(multiplier):
	$VBoxContainer/FunctionButtons/Attack.disabled = false
	
	test_enemy_attack()
	
func _on_enemy_attack_finished(result: Dictionary):
	$VBoxContainer/FunctionButtons/Attack.disabled = false
	print(result)
	if int(result["damage"]) > 0:
		print("PLAYER TAKE DAMAGE: ", result["damage"])
