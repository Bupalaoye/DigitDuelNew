extends Node2D

signal left_mouse_clicked
signal left_mouse_released
signal deck_clicked

# leyer is pow(2,n) 
const COLLISION_CARD_LAYER = 1
const COLLISION_CARD_SLOT_LAYER = 2
const COLLISION_CARD_DECK_LAYER = 4

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			raycast_at_cursor()
			left_mouse_clicked.emit()
		else:
			left_mouse_released.emit()

func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var paramters = PhysicsPointQueryParameters2D.new()
	paramters.position = get_global_mouse_position()
	paramters.collide_with_areas = true
	paramters.collision_mask = COLLISION_CARD_LAYER | COLLISION_CARD_SLOT_LAYER | COLLISION_CARD_DECK_LAYER
	var result = space_state.intersect_point(paramters)
	if result.size() > 0:
		var highest_card = get_highest_z_index_result(result)
		var result_collision_mask = highest_card.collider.collision_layer
		if result_collision_mask == COLLISION_CARD_LAYER:
			var card_found = highest_card.collider.get_parent()
			CardManager.start_drag(card_found)
		elif result_collision_mask == COLLISION_CARD_SLOT_LAYER:
			print('card slot clicked')
		elif result_collision_mask ==  COLLISION_CARD_DECK_LAYER:
			deck_clicked.emit()
	return null


func get_highest_z_index_result(results: Array) -> Dictionary:
	if results.is_empty():
		return {}

	var highest_result = results[0]
	var highest_z_index = highest_result.collider.get_parent().z_index
	
	for i in range(1, results.size()):
		var current_result = results[i]
		var current_parent = current_result.collider.get_parent()
		if current_parent.z_index > highest_z_index:
			highest_z_index = current_parent.z_index
			highest_result = current_result
			
	return highest_result
