extends Node2D

signal on_hovered
signal on_hovered_off

@onready var area_2d: Area2D = %Area2D
@onready var display_image: Sprite2D = %DisplayImage
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var def: Label = %DEF
@onready var atk: Label = %ATK
@onready var animation_player: AnimationPlayer = %AnimationPlayer

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
	area_2d.mouse_entered.connect(_on_hovered)
	area_2d.mouse_exited.connect(_on_hovered_off)
	CardManager.connect_card_signals(self)
	play_flip_anim()

func is_interactable() -> bool:
	return !(is_draging or is_in_slot or CardManager.card_being_dragged or is_player_card)

func _on_hovered():
	if !is_interactable(): return
	highlight_card(true)
	on_hovered.emit(self)
	
func _on_hovered_off():
	if !is_interactable(): return
	highlight_card(false)
	on_hovered_off.emit(self)


func highlight_card(hovered):
	if hovered:
		self.scale = Vector2(1.1, 1.1)
		self.z_index = 2
	else:
		self.scale = Vector2(1, 1)
		self.z_index = 1


func set_in_slot(state: bool):
	is_in_slot = state
	collision_shape_2d.disabled = state
	self.scale = Vector2(.9, .9) if state else Vector2(1, 1)
	self.z_index = 1

func start_drag(state: bool):
	self.is_draging = state
	self.scale = Vector2(1, 1) if state else Vector2(1, 1)


func update_visual():
	if not card_data:
		return
	display_image.texture = load(self.card_data.texture_path)
	self.current_atk = card_data.atk
	self.current_def = card_data.def

	update_stats_display()

	self.name = card_data.card_name
	
func update_stats_display():
	atk.text = str(max(self.current_atk,0))
	def.text = str(max(self.current_def,0))

func play_flip_anim():
	animation_player.play("card_flip")

func play_hit_animation():
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(self, 'modulate', Color.RED, .1)
	tween.tween_property(self, 'modulate', Color.WHITE, .1)
