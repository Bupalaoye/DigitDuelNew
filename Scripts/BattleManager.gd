extends Node

@onready var end_turn: Button = %EndTurn
@onready var battle_timer: Timer = %BattleTimer
@onready var opponent_deck: Deck = %OpponentDeck
@onready var opponent_hand: Hand = $"../Hands/OpponentHand"
@onready var player_deck: Deck = %PlayerDeck
@onready var card_slots_manager: CardSlotsManager = %CardSlotsManager
@onready var opponent_hp_label: Label = %OpponentHP
@onready var player_hp_label: Label = %PlayerHP
@onready var main_camera: Camera2D = %MainCamera

const OPPONENT_CARD_SPEED = .4
const ATTACK_ANIM_DURATION = 0.3
const PAUSE_BETWEEN_ATTACKS = 0.4

# const HIT_EFFECT_SCENE = preload("res://Scenes/HitEffect.tscn")
const ATTACK_CHARGE_DURATION = 0.4
const ATTACK_SPIN_DURATION = 0.3
const ATTACK_DASH_DURATION = 0.15


const PLAYER_HP: int = 30
const OPPONENT_HP: int = 30
var cur_player_hp: int = 0
var cur_opponent_hp: int = 0


func _ready() -> void:
	end_turn.pressed.connect(_on_end_turn_pressed)
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	self.cur_player_hp = PLAYER_HP
	self.cur_opponent_hp = OPPONENT_HP
	update_hp_display()


func _on_end_turn_pressed() -> void:
	end_turn.disabled = true
	
	await start_battle_phase()
	await opponent_turn()


func opponent_turn() -> void:
	end_turn.visible = false
	
	opponent_deck.on_new_turn_started()
	await get_tree().create_timer(1.0).timeout
	
	if opponent_deck.player_deck.size() != 0:
		opponent_deck.draw_card()
		await get_tree().create_timer(1.0).timeout
		
	if card_slots_manager.has_any_free_opponent_card_slot():
		await try_play_card_with_highest_card()
	
	end_opponent_turn()


func end_opponent_turn() -> void:
	end_turn.disabled = false
	end_turn.visible = true
	player_deck.on_new_turn_started()
	if player_deck.player_deck.size() != 0:
		player_deck.draw_card()


func try_play_card_with_highest_card() -> void:
	if opponent_hand.cards_in_hand.size() == 0:
		return
	
	var random_opponent_target_slot = card_slots_manager.get_free_opponent_card_slots().pick_random()
	if not random_opponent_target_slot: return

	var highest_card = opponent_hand.get_highest_attack_card()
	if not highest_card: return
	
	opponent_hand.remove_card_from_hand(highest_card)

	var move_tween = get_tree().create_tween()
	# 1. move card to slot 
	move_tween.tween_property(highest_card, 'position', random_opponent_target_slot.position, OPPONENT_CARD_SPEED)
	highest_card.play_flip_anim()
	
	# update card state and slot info
	highest_card.set_state(highest_card.CardState.IN_SLOT)
	random_opponent_target_slot.card_instance = highest_card
	random_opponent_target_slot.card_in_slot = true
	
	await get_tree().create_timer(0.5).timeout


# ==================================================================
# --- 核心战斗逻辑 (已重构) ---
# ==================================================================

func start_battle_phase() -> void:
	print("--- Battle Phase Started ---")
	
	var all_slots = card_slots_manager.get_children()
	var opponent_slots = all_slots.slice(0, card_slots_manager.slots_per_player)
	var player_slots = all_slots.slice(card_slots_manager.slots_per_player)
	
	for i in range(player_slots.size()):
		var p_slot = player_slots[i]
		var o_slot = opponent_slots[i]
		
		if is_instance_valid(p_slot.card_instance) and is_instance_valid(o_slot.card_instance):
			print("Combat between Player's %s and Opponent's %s" % [p_slot.card_instance.name, o_slot.card_instance.name])
			await resolve_combat(p_slot.card_instance, o_slot.card_instance)
			await get_tree().create_timer(PAUSE_BETWEEN_ATTACKS).timeout

	print("--- Battle Phase Finished ---")


## --- 重构后的核心战斗函数 ---
## 解析单次战斗，现在是同时结算伤害
func resolve_combat(player_card: Node2D, opponent_card: Node2D) -> void:
	# 1. 数据准备
	var player_atk = player_card.current_atk
	var opponent_atk = opponent_card.current_atk

	var attacker = player_card
	var target = opponent_card

	var original_pos = attacker.position
	var target_pos = target.position
	# 蓄力位置：在原位置左上方
	var charge_pos = original_pos + Vector2(-100, -150)

	# --- 2. 动画序列开始 ---
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# **分镜1: 蓄力 - 移动到左上角**
	# 播放充能音效 (假设你有一个AudioStreamPlayer叫SFXPlayer)
	# $SFXPlayer.stream = load("res://sounds/charge_up.wav")
	# $SFXPlayer.play()
	tween.tween_property(attacker, "position", charge_pos, ATTACK_CHARGE_DURATION)

	# **分镜2: 力量积蓄 - 快速旋转**
	# 使用 chain() 来确保这个动画在上一个动画结束后开始
	# 使用 parallel() 来让位移和旋转同时进行
	tween.chain().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var spin_tween = tween.parallel()
	spin_tween.tween_property(attacker, "rotation_degrees", 720, ATTACK_SPIN_DURATION) # 旋转2圈
	spin_tween.tween_property(attacker, "scale", attacker.scale * 1.2, ATTACK_SPIN_DURATION) # 旋转时稍微变大

	# **分镜3: 攻击 - 冲刺向目标**
	# 播放冲刺音效
	# $SFXPlayer.stream = load("res://sounds/whoosh.wav")
	# $SFXPlayer.play()
	tween.chain().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO) # 使用指数缓动模拟爆发力
	tween.tween_property(attacker, "position", target_pos, ATTACK_DASH_DURATION)

	# 等待冲刺动画完成
	await tween.finished

	# --- 3. 命中瞬间 ---

	# 播放命中音效和屏幕特效
	# $SFXPlayer.stream = load("res://sounds/impact.wav")
	# $SFXPlayer.play()
	self.main_camera.shake_camera(10, 0.2) # 调用镜头震动

	# 在目标位置生成打击特效
	# var hit_effect = HIT_EFFECT_SCENE.instantiate()
	# target.add_child(hit_effect) # 将特效加为子节点，这样它会跟随卡牌
	# hit_effect.global_position = target.global_position

	# 同时计算伤害和更新UI
	player_card.current_def -= opponent_atk
	opponent_card.current_def -= player_atk
	player_card.update_stats_display()
	opponent_card.update_stats_display()

	# 同时播放双方的受击动画
	player_card.play_hit_animation()
	opponent_card.play_hit_animation()

	# --- 4. 动画收尾 ---

	# 等待一小段时间，让玩家看清伤害结果
	await get_tree().create_timer(0.1).timeout

	# 攻击者返回原位
	var return_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return_tween.tween_property(attacker, "position", original_pos, 0.2)
	return_tween.tween_property(attacker, "rotation_degrees", 0, 0.2) # 旋转归位
	return_tween.tween_property(attacker, "scale", attacker.base_scale, 0.2) # 大小归位
	await return_tween.finished

	# --- 5. 检查卡牌阵亡 ---
	if player_card.current_def <= 0:
		await destroy_card(player_card)
	if opponent_card.current_def <= 0:
		await destroy_card(opponent_card)


## 处理卡牌阵亡 (无需改动)
func destroy_card(card_to_destroy: Node2D) -> void:
	print("%s has been destroyed!" % card_to_destroy.name)

	var slot_of_card = find_slot_for_card(card_to_destroy)
	if slot_of_card:
		slot_of_card.card_in_slot = false
		slot_of_card.card_instance = null

	var tween = create_tween()
	tween.tween_property(card_to_destroy, "modulate:a", 0.0, 0.4)
	await tween.finished
	
	if is_instance_valid(card_to_destroy):
		card_to_destroy.queue_free()


## 辅助函数 (无需改动)
func find_slot_for_card(card_instance: Node2D) -> Node2D:
	for slot in card_slots_manager.get_children():
		if slot.card_instance == card_instance:
			return slot
	return null

func update_hp_display():
	if player_hp_label:
		player_hp_label.text = "Player HP: %d" % max(0, self.cur_player_hp)
	if opponent_hp_label:
		opponent_hp_label.text = "Opponent HP: %d" % max(0, self.cur_opponent_hp)
