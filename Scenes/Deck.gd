extends Node2D

const CARD_SCENE = preload("uid://bnqfvwkx3esd")
const HAND_COUNT = 8
var player_deck = ['2' , '2' , '2' , '2']

@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect
@onready var card_num: RichTextLabel = %CardNum

func _ready() -> void:
	InputManager.deck_clicked.connect(on_deck_clicked)
	card_num.text = str(player_deck.size())

func draw_card():
	var card_drawn = player_deck[0]
	player_deck	.erase(card_drawn)
	
	# update text
	card_num.text = str(player_deck.size())
	
	# empty then hidden
	if player_deck.size() == 0:
		collision_shape_2d.disabled = true
		color_rect.visible = false
	# instance new card
	var new_card = CARD_SCENE.instantiate()
	new_card.position = self.position
	CardManager.add_child(new_card)
	new_card.name = 'Card'
	PlayerHand.add_card_to_hand(new_card, .4)

func on_deck_clicked():
	draw_card()
