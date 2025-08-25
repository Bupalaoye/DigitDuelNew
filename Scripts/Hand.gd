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

var cards_in_hand: Array[Node2D] = []

# record cur dragged card in hand
var dragged_card_in_hand: Card = null
# record the index of the placeholder for the dragged card
var placeholder_index: int = -1

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

func update_hand_positions(speed: float):
	# create tmp cards list 
	var cards_to_position = cards_in_hand.duplicate()
	if is_instance_valid(dragged_card_in_hand):
		# if dragging, remove it from the list to position
		cards_to_position.erase(dragged_card_in_hand)

	var hand_size = cards_to_position.size()
	
	# if dragging, the layout size is hand size + 1 (for placeholder)
	# else just hand size
	var layout_size = hand_size + 1 if is_instance_valid(dragged_card_in_hand) else hand_size
	if layout_size == 0:
		return

	var total_arc_angle = min((layout_size - 1) * angle_pre_card, max_arc_angle)
	var start_angle_deg = - total_arc_angle / 2.0 
	if not self.is_player_hand:
		start_angle_deg += 180

	var angle_step_deg = total_arc_angle / (layout_size - 1) if layout_size > 1 else 0

	var card_idx = 0
	for i in range(layout_size):
		# if dragging, skip the placeholder index
		if is_instance_valid(dragged_card_in_hand) and i == placeholder_index:
			continue

		# safety check
		if card_idx >= cards_to_position.size():
			break
			
		var card = cards_to_position[card_idx]
		card_idx += 1
		
		var card_angle_deg = start_angle_deg + i * angle_step_deg
		var card_angle_rad = deg_to_rad(card_angle_deg)
		
		var target_pos: Vector2 = arc_center_offset + Vector2(
			arc_radius * sin(card_angle_rad),
			-1 * arc_radius * cos(card_angle_rad)
		)
		
		card.starting_rotation = card_angle_deg
		card.move_to_layout_transform(target_pos, card_angle_deg, speed)


# sort card in hand
func start_reordering(card: Card):
	if not is_player_hand: return # only player hand can reorder
	if card in cards_in_hand:
		dragged_card_in_hand = card
		# set placeholder index to current card index else -1
		placeholder_index = cards_in_hand.find(card)
		update_hand_positions(0.1)


# update placeholder position based on mouse position
func update_placeholder(mouse_pos: Vector2):
	if not is_instance_valid(dragged_card_in_hand):
		return

	var new_index = 0
	# iterate through cards in hand to find new index 
	for card in cards_in_hand:
		if card == dragged_card_in_hand:
			continue
		# if mouse x is greater than card x position, move to next index
		if mouse_pos.x > card.global_position.x - (card.display_image.size.x * card.display_image.scale.x / 2):
			new_index += 1
	
	# if new index is different from current placeholder index, update and refresh layout
	if new_index != placeholder_index:
		placeholder_index = new_index
		update_hand_positions(0.1)


# called by CardManager when drag ends
func finish_reordering():
	if not is_instance_valid(dragged_card_in_hand):
		return
		
	var card_to_reorder = dragged_card_in_hand
	
	# clear the dragged card reference
	dragged_card_in_hand = null
	
	# remove from current position
	cards_in_hand.erase(card_to_reorder)
	# insert at placeholder index
	cards_in_hand.insert(placeholder_index, card_to_reorder)
	
	# update the state 
	card_to_reorder.set_state(Card.CardState.IN_HAND)

	# reset placeholder index
	placeholder_index = -1
	update_hand_positions(0.2)

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
