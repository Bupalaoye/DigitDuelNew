extends Node2D


@export var is_player := false

@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var card_num: RichTextLabel = %CardNum
@onready var display_image: Sprite2D = %DisplayImage
const CARD_SCENE = preload("uid://bnqfvwkx3esd")
const HAND_COUNT = 8
var player_deck = []
var drawn_card_this_turn := false
var PLAYER_STARTING_CARD_NUM := 6


func _ready() -> void:
	player_deck = CardDataBase.get_card_asset_names()
	card_num.text = str(player_deck.size())
	# 洗牌
	player_deck.shuffle()

	if is_player:
		InputManager.deck_clicked.connect(on_deck_clicked)
		for i in range(PLAYER_STARTING_CARD_NUM):
			draw_card()
		drawn_card_this_turn = true

func draw_card():
	if drawn_card_this_turn: return
	
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
	new_card.position = self.position
	CardManager.add_child(new_card)
	var card_image_path = str('res://PlayingCards/individual_sprites/%s.png' % card_drawn)
	new_card.set_image_by_path(card_image_path)
	new_card.name = card_drawn
	PlayerHand.add_card_to_hand(new_card, .4)

func on_deck_clicked():
	if is_player:
		draw_card()
