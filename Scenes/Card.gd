extends Node2D
class_name Card

signal on_hovered
signal on_hovered_off

@onready var area_2d: Area2D = %Area2D
@onready var display_image: TextureRect = %DisplayImage
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var def: Label = %DEF
@onready var atk: Label = %ATK
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# define card states
enum CardState {
	IN_DECK,
	IN_HAND,
	IN_SLOT,
	DRAGGING,
	IN_VIEW
}

# state scales 
@export_group('State Scales')
@export var in_hand_scale: Vector2 = Vector2(1, 1)
@export var in_slot_scale: Vector2 = Vector2(0.9, 0.9)
@export var in_dragging_scale: Vector2 = Vector2(1.1, 1.1)
@export var in_view_scale: Vector2 = Vector2(1.5, 1.5)


@export_group('state z-index')
@export var in_hand_z_index: int = 10
@export var in_slot_z_index: int = 5
@export var dragging_z_index: int = 100

@export_group('hover effect')
@export var hover_scale_multiplier: float = 1.15
@export var hover_z_offset: int = 1
@export_group('')

# default anim duration
@export var transition_duration: float = 0.15

# tracing cur state
var current_state: CardState = CardState.IN_DECK
var base_scale: Vector2 = Vector2.ZERO
var base_z_index: int = 0
var is_hovered: bool = false


var starting_position := Vector2(0, 0)
var is_draging := false
var is_in_slot := false
var is_player_card := false
var current_hand = null # ADDED: 用于引用卡牌所在的Hand节点
var card_data: CardData = null

# battle properties
var current_atk: int = 0
var current_def: int = 0


func _ready() -> void:
	if !is_player_card: return
	area_2d.mouse_entered.connect(_on_mouse_entered)
	area_2d.mouse_exited.connect(_on_mouse_exited)
	CardManager.connect_card_signals(self)
	play_flip_anim()

func set_state(new_state: CardState):
	if new_state == current_state:
		return
	
	current_state = new_state
	match new_state:
		CardState.IN_HAND:
			base_scale = in_hand_scale
			base_z_index = in_hand_z_index
			collision_shape_2d.disabled = false
		CardState.IN_SLOT:
			base_scale = in_slot_scale
			base_z_index = in_slot_z_index
			collision_shape_2d.disabled = true
		CardState.DRAGGING:
			base_scale = in_dragging_scale
			base_z_index = dragging_z_index
			collision_shape_2d.disabled = false
		CardState.IN_VIEW:
			pass
		
	_update_visuals()


func _update_visuals():
	var target_scale = base_scale
	var target_z_index = base_z_index
	
	# check whether hovered
	if is_hovered:
		target_scale *= hover_scale_multiplier
		target_z_index += hover_z_offset
	
	# play anim by tween
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, 'scale', target_scale, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	self.z_index = target_z_index


func is_interactable() -> bool:
	# return !(is_draging or is_in_slot or CardManager.card_being_dragged or is_player_card)
	return current_state == CardState.IN_HAND and not CardManager.card_being_dragged and is_player_card

func _on_mouse_entered():
	if !is_interactable(): return
	self.is_hovered = true
	_update_visuals()
	on_hovered.emit(self)
	
func _on_mouse_exited():
	if !is_interactable(): return
	is_hovered = false
	_update_visuals()
	on_hovered_off.emit(self)

func update_visual():
	if not card_data:
		return
	display_image.texture = load(self.card_data.texture_path)
	self.current_atk = card_data.atk
	self.current_def = card_data.def

	update_stats_display()

	self.name = card_data.card_name
	
func update_stats_display():
	atk.text = str(max(self.current_atk, 0))
	def.text = str(max(self.current_def, 0))

func play_flip_anim():
	animation_player.play("card_flip")

func play_hit_animation():
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale * 1.1, 0.1)
	tween.tween_property(self, "scale", base_scale, 0.1)
	tween.tween_property(self, 'modulate', Color.RED, .1)
	tween.tween_property(self, 'modulate', Color.WHITE, .1)
