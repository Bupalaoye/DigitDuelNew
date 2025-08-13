extends Node2D

const COLLISION_CARD_MASK = 1
const COLLISION_CARD_SLOT_MASK = 2
var card_being_dragged = null
var screen_size
var is_hovering_card = false

func _ready() -> void:
	screen_size = get_viewport_rect().size
	InputManager.left_mouse_clicked.connect(on_left_mouse_clicked)
	InputManager.left_mouse_released.connect(on_left_mouse_released)

func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		mouse_pos.x = clampf(mouse_pos.x, 0, screen_size.x)
		mouse_pos.y = clampf(mouse_pos.y, 0, screen_size.y)
		card_being_dragged.position = mouse_pos


func on_left_mouse_clicked():
	pass

func on_left_mouse_released():
	if card_being_dragged:
		finish_drag()

func start_drag(card):
	card_being_dragged = card
	card.start_drag(true)
	

func finish_drag():
	if card_being_dragged:
		# ADDED: 获取卡牌拖拽前的所属手牌
		var original_hand = card_being_dragged.current_hand
		
		var card_slot_found = raycast_check_for_card_slot()
		
		# MODIFIED: 只有玩家的卡牌才能放入玩家的槽位
		if card_slot_found and not card_slot_found.card_in_slot and card_slot_found.owner_is_player and card_being_dragged.is_player_card:
			# MODIFIED: 从其原始手牌中移除
			if original_hand:
				original_hand.remove_card_from_hand(card_being_dragged)
				
			card_being_dragged.set_in_slot(true)
			card_slot_found.card_in_slot = true
			card_being_dragged.position = card_slot_found.position
		else:
			# MODIFIED: 返回到其原始手牌
			if original_hand:
				original_hand.add_card_to_hand(card_being_dragged, 0.2) # 使用一个较快的速度返回
			else:
				# 如果卡牌没有原始手牌（异常情况），则销毁或放到弃牌堆
				push_warning("Dragged card has no original hand to return to. Hiding card.")
				card_being_dragged.hide()

		card_being_dragged.is_draging = false
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
		is_hovering_card = true
	
func on_hovered_off_card(card):
	if !card_being_dragged:
		var new_card_hovered = raycast_check_for_card()
		if !new_card_hovered:
			is_hovering_card = false
