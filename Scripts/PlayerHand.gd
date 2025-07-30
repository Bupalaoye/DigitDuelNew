extends Node2D

const CARD_WITDH = 60
const DEFAULT_CARD_MOVE_SPEED = 0.1
var HAND_Y_POSITON = 0
var player_hand = []
var center_screen_x = 0


func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	HAND_Y_POSITON = get_viewport().size.y - 50
	

func add_card_to_hand(card, speed):
	if card in player_hand:
		animation_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED)
	else:
		player_hand.insert(0, card)
		update_hand_positions(speed)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

func update_hand_positions(speed):
	for i in range(player_hand.size()):
		# get new card position based on index
		var new_position = Vector2 (calculate_card_position(i), HAND_Y_POSITON)
		animation_card_to_position(player_hand[i], new_position, speed)
		
func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WITDH
	var x_offset = center_screen_x + index * CARD_WITDH - total_width / 2
	return x_offset

func animation_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	card.starting_position = new_position
	tween.tween_property(card,'position',new_position, speed)
