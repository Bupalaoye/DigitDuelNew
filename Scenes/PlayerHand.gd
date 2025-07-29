extends Node2D

const CARD_WITDH = 60
const CARD_SCENE = preload("res://Scenes/Card.tscn")
const HAND_COUNT = 8
var HAND_Y_POSITON = 0


@onready var card_manager: Node2D = %CardManager

var player_hand = []
var center_screen_x = 0


func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	HAND_Y_POSITON = get_viewport().size.y - 50
	for i in range(HAND_COUNT):
		var new_card = CARD_SCENE.instantiate()
		card_manager.add_child(new_card)
		new_card.name = 'Card'
		add_card_to_hand(new_card)

func add_card_to_hand(card):
	if card in player_hand:
		animation_card_to_position(card, card.starting_position)
	else:
		player_hand.insert(0, card)
		update_hand_positions()

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()

func update_hand_positions():
	for i in range(player_hand.size()):
		# get new card position based on index
		var new_position = Vector2 (calculate_card_position(i), HAND_Y_POSITON)
		animation_card_to_position(player_hand[i], new_position)
		
func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WITDH
	var x_offset = center_screen_x + index * CARD_WITDH - total_width / 2
	return x_offset

func animation_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	card.starting_position = new_position
	tween.tween_property(card,'position',new_position,0.1)
