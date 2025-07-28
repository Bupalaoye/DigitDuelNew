extends Node2D

const COLLISION_CARD_MASK = 1
const COLLISION_CARD_SLOT_MASK = 2
var card_being_dragged = null
var screen_size
var is_hovering_card = false

func _ready() -> void:
	screen_size = get_viewport_rect().size
	


func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		mouse_pos.x = clampf(mouse_pos.x, 0, screen_size.x)
		mouse_pos.y = clampf(mouse_pos.y, 0, screen_size.y)
		card_being_dragged.position = mouse_pos
		

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var card  = raycast_check_for_card()
			if card:
				start_drag(card)
		else:
			finish_drag()

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(1,1)

func finish_drag():
	if card_being_dragged:
		card_being_dragged.scale = Vector2(1.1, 1.1)
		var card_slot_found = raycast_check_for_card_slot()
		if card_slot_found and not card_slot_found.card_in_slot:
			card_being_dragged.position = card_slot_found.position
			card_slot_found.card_in_slot = true
			card_being_dragged.get_node('Area2D/CollisionShape2D').disabled = true
			
		card_being_dragged = null


func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var paramters = PhysicsPointQueryParameters2D.new()
	paramters.position = get_global_mouse_position()
	paramters.collide_with_areas = true
	paramters.collision_mask = COLLISION_CARD_MASK
	var result = space_state.intersect_point(paramters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null


func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var paramters = PhysicsPointQueryParameters2D.new()
	paramters.position = get_global_mouse_position()
	paramters.collide_with_areas = true
	paramters.collision_mask = COLLISION_CARD_SLOT_MASK
	var result = space_state.intersect_point(paramters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	var highest_card = cards[0].collider.get_parent()
	var highest_z_index = highest_card.z_index
	
	for i in range(1, cards.size()):
		var cur_card = cards[i].collider.get_parent()
		if cur_card.z_index > highest_z_index:
			highest_z_index = cur_card.z_index
			highest_card = cur_card
	return highest_card


func connect_card_signals(card):
	card.on_hovered.connect(on_hovered_over_card)
	card.on_hovered_off.connect(on_hovered_off_card)

func on_hovered_over_card(card):
	if !is_hovering_card:
		highlight_card(card, true)
		is_hovering_card = true
	
func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_card = false


func highlight_card(card , hovered):
	if hovered:
		card.scale = Vector2(1.1, 1.1)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1 )
		card.z_index = 1
