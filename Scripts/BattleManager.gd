extends Node
@onready var end_turn: Button = %EndTurn
@onready var battle_timer: Timer = %BattleTimer
@onready var opponent_deck: Deck = %OpponentDeck
@onready var opponent_hand: Hand = $"../Hands/OpponentHand"
@onready var player_deck: Deck = %PlayerDeck
@onready var card_slots_manager: CardSlotsManager = %CardSlotsManager

const OPPONENT_CARD_SPEED = .4
func _ready() -> void:
	end_turn.pressed.connect(_on_end_turn_pressed)
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0

func _on_end_turn_pressed() -> void:
	opponent_turn()


func opponent_turn():
	end_turn.disabled = true
	end_turn.visible = false
	
	opponent_deck.on_new_turn_started()
	battle_timer.start()
	await  battle_timer.timeout
	
	# if can draw a card , drawn then wait 1 second 
	if opponent_deck.player_deck.size() != 0:
		opponent_deck.draw_card()
		battle_timer.start()
		await  battle_timer.timeout
		
	# check if any free monster card slots , and if no ,end turn 
	if !card_slots_manager.has_any_free_opponent_card_slot():
		end_opponent_turn()
		return
	
	await try_play_card_with_highest_card()
	
	end_opponent_turn()

func end_opponent_turn():
	end_turn.disabled = false
	end_turn.visible = true
	player_deck.on_new_turn_started()
	if player_deck.player_deck.size() != 0:
		player_deck.draw_card()

func try_play_card_with_highest_card():
	# play the card in hard with highest attack 
	if opponent_hand.cards_in_hand.size() == 0:
		end_opponent_turn()
		return 
	
	var random_opponent_target_slot = card_slots_manager.get_free_opponent_card_slots().pick_random()
	var highest_card = opponent_hand.get_highest_attack_card()
	
	# animate card to position
	var tween = get_tree().create_tween()
	tween.tween_property(highest_card,'position',random_opponent_target_slot.position,OPPONENT_CARD_SPEED)
	highest_card.play_flip_anim()
	opponent_hand.cards_in_hand.erase(highest_card)
	opponent_hand.update_hand_positions(OPPONENT_CARD_SPEED)
	
	battle_timer.start()
	await  battle_timer.timeout
