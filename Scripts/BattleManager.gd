extends Node
@onready var end_turn: Button = %EndTurn
@onready var battle_timer: Timer = %BattleTimer
@onready var opponent_deck: Deck = %OpponentDeck
@onready var player_deck: Deck = %PlayerDeck

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
	player_deck.on_new_turn_started()
	battle_timer.start()
	await  battle_timer.timeout
	
	if opponent_deck.player_deck.size() != 0:
		opponent_deck.draw_card()
		battle_timer.start()
		await  battle_timer.timeout
	
	end_opponent_turn()

func end_opponent_turn():
	end_turn.disabled = false
	end_turn.visible = true
