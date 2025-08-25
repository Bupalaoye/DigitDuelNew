class_name Hand
extends Node2D

const DEFAULT_CARD_MOVE_SPEED = 0.1
# const CARD_SPACING = 180

# ADDED: 导出变量，用于在编辑器中配置
@export var is_player_hand: bool = true # 用来区分是玩家手牌还是对手手牌
# @export var hand_y_position: float = 0 # 手牌区域的Y坐标
# @export var center_screen_x: float = 0.0

@export_group('arc layout')
@export var arc_center_offset: Vector2 = Vector2(576, 850)
# the radius of the arc (in pixels) that the cards will be arranged along
@export var arc_radius: float = 800.0
# the spacing (in pixels) between cards in the hand
@export var angle_pre_card: float = 5.0
# the max arc angle (in degrees) that the cards will be spread out over
@export var max_arc_angle: float = 60.0

# MODIFIED: 变量名从 player_hand 改为 cards_in_hand
var cards_in_hand: Array[Node2D] = []


func _ready() -> void:
	pass

func add_card_to_hand(card: Node2D, speed: float):
	# ADDED: 当卡牌被加入手牌时，记录它属于哪个手牌
	card.current_hand = self

	# notify card state
	card.set_state(card.CardState.IN_HAND)

	if card in cards_in_hand:
		pass
	else:
		if not self.is_player_hand:
			cards_in_hand.insert(0, card)
		else:
			cards_in_hand.append(card)

	# ADDED: 确保卡牌的起始位置正确
	update_hand_positions(speed)

func remove_card_from_hand(card: Node2D):
	if card in cards_in_hand:
		# ADDED: 卡牌离开手牌，清除引用
		card.current_hand = null
		cards_in_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

# --- 这是修复和优化的核心函数 ---
func update_hand_positions(speed: float):
	var hand_size = cards_in_hand.size()
	if hand_size == 0:
		return

	# 1. 计算当前手牌应该展开的总角度
	# (hand_size - 1) * angle_pre_card 是理论总角度
	# 我们用 min() 来确保它不会超过设定的最大值 max_arc_angle
	var total_arc_angle = min((hand_size - 1) * angle_pre_card, max_arc_angle)

	# 2. 计算第一张牌的起始角度
	# 为了让整个弧形居中，我们将总角度的一半作为负的起始点
	var start_angle_deg = - total_arc_angle / 2.0 
	if not self.is_player_hand:
		# 对手卡牌反一下
		start_angle_deg += 180
	# 3. 计算每张牌之间的角度步长
	# 如果只有一张牌，步长为0，它会正好在中间
	var angle_step_deg = total_arc_angle / (hand_size - 1) if hand_size > 1 else 0

	# 4. 遍历所有手牌，计算并应用它们的新位置和旋转
	for i in range(hand_size):
		var card = cards_in_hand[i]
		
		# a. 计算当前卡牌的目标角度
		var card_angle_deg = start_angle_deg + i * angle_step_deg
		# 将角度转换为弧度，因为Godot的sin/cos函数使用弧度
		var card_angle_rad = deg_to_rad(card_angle_deg)
		
		# b. 计算卡牌的目标位置 (极坐标转笛卡尔坐标)
		# 我们以 arc_center_offset 为圆心，arc_radius 为半径来计算位置
		# 我们从上方(PI/2)开始计算，所以要减去 card_angle_rad
		var target_pos: Vector2 = Vector2.ZERO
		target_pos = arc_center_offset + Vector2(
			arc_radius * sin(card_angle_rad), # X坐标
			-1 * arc_radius * cos(card_angle_rad) # Y坐标
		)
		# c. update layout
		card.starting_rotation = card_angle_deg
		card.move_to_layout_transform(target_pos, card_angle_deg, speed)

func get_highest_attack_card() -> Node2D:
	# 1. 处理边缘情况：如果手牌是空的，直接返回 null。
	if cards_in_hand.is_empty():
		return null

	# 2. 初始化追踪变量。
	#    我们将从一个非常低的值开始，以确保任何卡牌的攻击力都比它高。
	var highest_card: Node2D = null
	var highest_atk_value = -1

	# 3. 遍历手牌中的每一张卡牌。
	for card in cards_in_hand:
		# 安全检查：确保卡牌有数据 (card_data) 并且数据中有攻击力 (atk) 属性。
		if card.card_data and card.card_data.atk > highest_atk_value:
			# 4. 如果当前卡牌的攻击力更高，就更新我们的追踪变量。
			highest_atk_value = card.card_data.atk
			highest_card = card
			
	# 5. 循环结束后，highest_card 就是攻击力最高的卡牌。返回它。
	return highest_card
