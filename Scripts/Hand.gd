extends Node2D

const CARD_WITDH = 60
const DEFAULT_CARD_MOVE_SPEED = 0.1
const CARD_SPACING = 60

# ADDED: 导出变量，用于在编辑器中配置
@export var is_player_hand: bool = true # 用来区分是玩家手牌还是对手手牌
@export var hand_y_position: float = 0 # 手牌区域的Y坐标
@export var card_scale: float = 1.0 # 手牌中卡牌的缩放
@export var card_z_index: int = 1 # 手牌中卡牌的基础Z-Index
@export var center_screen_x: float = 0.0

# MODIFIED: 变量名从 player_hand 改为 cards_in_hand
var cards_in_hand: Array[Node2D] = []


func _ready() -> void:
	pass

func add_card_to_hand(card: Node2D, speed: float):
	# ADDED: 当卡牌被加入手牌时，记录它属于哪个手牌
	card.current_hand = self

	if card in cards_in_hand:
		animation_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED)
	else:
		cards_in_hand.insert(0, card)
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

	# 1. 计算手牌的总宽度
	# 这是从第一张牌的中心到最后一张牌的中心的距离。
	# 例如，3张牌有2个间距。
	var total_hand_width = (hand_size - 1) * CARD_SPACING

	# 2. 计算第一张牌的起始X坐标
	# 算法：从屏幕中心点向左移动总宽度的一半，这样整个手牌区域就会居中。
	var start_x = center_screen_x - (total_hand_width / 2.0)
	# 3. 遍历所有手牌并设置它们的新位置
	for i in range(hand_size):
		var card = cards_in_hand[i]
		# 计算当前卡牌的中心X坐标
		var target_x = start_x + (i * CARD_SPACING)
		# 创建目标位置向量
		var new_position = Vector2(target_x, hand_y_position)
		
		# 播放动画将卡牌移动到新位置
		animation_card_to_position(card, new_position, speed)
		
		# 更新卡牌的视觉属性
		card.scale = Vector2(card_scale, card_scale)
		# 确保手牌的 z_index 足够高，以免被场上元素遮挡
		card.z_index = card_z_index + i # 让卡牌有轻微的层叠效果

func animation_card_to_position(card: Node2D, new_position: Vector2, speed: float):
	var tween = get_tree().create_tween()
	card.starting_position = new_position
	tween.tween_property(card, "position", new_position, speed)
	# 如果是对手手牌，可以考虑加上旋转，让牌背朝向玩家
	if !is_player_hand:
		# 示例：对手手牌可以翻转
		# tween.tween_property(card, "rotation_degrees", 180, speed)
		pass
