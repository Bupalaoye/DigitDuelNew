extends Node

@onready var end_turn: Button = %EndTurn
@onready var battle_timer: Timer = %BattleTimer
@onready var opponent_deck: Deck = %OpponentDeck
@onready var opponent_hand: Hand = $"../Hands/OpponentHand"
@onready var player_deck: Deck = %PlayerDeck
@onready var card_slots_manager: CardSlotsManager = %CardSlotsManager
@onready var opponent_hp_label: Label = %OpponentHP
@onready var player_hp_label: Label = %PlayerHP

const OPPONENT_CARD_SPEED = .4
const ATTACK_ANIM_DURATION = 0.3
const PAUSE_BETWEEN_ATTACKS = 0.4

const PLAYER_HP : int = 30
const OPPONENT_HP :int = 30
var cur_player_hp : int = 0
var cur_opponent_hp : int = 0


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

	var tween = get_tree().create_tween()
	tween.tween_property(highest_card, 'position', random_opponent_target_slot.position, OPPONENT_CARD_SPEED)
	highest_card.play_flip_anim()
	highest_card.set_in_slot(true)
	random_opponent_target_slot.card_instance = highest_card
	random_opponent_target_slot.card_in_slot = true
	
	await get_tree().create_timer(1.0).timeout


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
	# 1. 预先记录双方的攻击力。这是关键！
	var player_atk = player_card.current_atk
	var opponent_atk = opponent_card.current_atk

	# 2. 播放攻击动画 (让玩家卡牌主动攻击)
	var original_pos = player_card.position
	var target_pos = opponent_card.position
	
	var tween = create_tween()
	tween.tween_property(player_card, "position", original_pos.lerp(target_pos, 0.3), ATTACK_ANIM_DURATION / 2.0).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(player_card, "position", original_pos, ATTACK_ANIM_DURATION / 2.0).set_trans(Tween.TRANS_SINE)
	
	await tween.finished

	# 3. 同时计算伤害
	print("Applying simultaneous damage...")
	player_card.current_def -= opponent_atk
	opponent_card.current_def -= player_atk

	# 4. 同时更新UI并播放受击动画
	player_card.update_stats_display()
	opponent_card.update_stats_display()
	player_card.play_hit_animation()
	opponent_card.play_hit_animation()
	
	print("%s's DEF is now %d. %s's DEF is now %d" % [player_card.name, player_card.current_def, opponent_card.name, opponent_card.current_def])

	# 5. 检查双方是否阵亡
	# 注意：这里我们使用 "if" 而不是 "elif"，因为有可能双方同时被击败
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
