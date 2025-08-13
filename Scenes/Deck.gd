extends Node2D


@export var is_player := false
# ADDED: 导出NodePath，用于在编辑器中指定此牌堆对应的手牌区
@export var target_hand_path: NodePath

@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var card_num: RichTextLabel = %CardNum
@onready var display_image: Sprite2D = %DisplayImage
const CARD_SCENE = preload("uid://bnqfvwkx3esd")
const HAND_COUNT = 8
var player_deck = []
var drawn_card_this_turn := false
var PLAYER_STARTING_CARD_NUM := 4

# ADDED: 在ready时获取手牌区的引用
var target_hand: Node2D

func _ready() -> void:
	# ADDED: 确保target_hand被正确设置
	if target_hand_path:
		target_hand = get_node(target_hand_path)
	else:
		push_warning("Deck %s has no target_hand assigned!" % self.name)


	player_deck = CardDataBase.get_card_asset_names()
	card_num.text = str(player_deck.size())
	# 洗牌
	player_deck.shuffle()

	if is_player:
		InputManager.deck_clicked.connect(on_deck_clicked)
		
	# MODIFIED: 只有当target_hand存在时才发牌
	if target_hand:
		for i in range(PLAYER_STARTING_CARD_NUM):
			draw_card(false) # 初始发牌不应受drawn_card_this_turn限制
	
	drawn_card_this_turn = true

# MODIFIED: draw_card函数现在不硬编码PlayerHand了
func draw_card(check_turn_limit: bool = true):
	if check_turn_limit and drawn_card_this_turn: return
	if player_deck.is_empty(): return
	# MODIFIED: 确保目标手牌区已设置
	if !target_hand:
		push_error("Cannot draw card: target_hand is not set for this deck.")
		return
	
	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	
	# update text
	card_num.text = str(player_deck.size())
	
	# empty then hidden
	if player_deck.size() == 0:
		collision_shape_2d.disabled = true
		display_image.visible = false
		
	# instance new card
	var new_card = CARD_SCENE.instantiate()
	new_card.is_player_card = self.is_player
	new_card.position = self.position
	CardManager.add_child(new_card) # 最好让一个专门的节点管理所有卡牌实例
	var card_image_path = str('res://PlayingCards/individual_sprites/%s.png' % card_drawn)
	new_card.set_image_by_path(card_image_path)
	new_card.name = card_drawn
	
	# MODIFIED: 调用目标手牌区的函数来添加卡牌
	target_hand.add_card_to_hand(new_card, .4)

func on_deck_clicked():
	if is_player:
		draw_card()
