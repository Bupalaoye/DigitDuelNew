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
var current_hand = null  # ADDED: 用于引用卡牌所在的Hand节点
var card_data : CardData = null


func _ready() -> void:
	if !is_player_card : return
	area_2d.mouse_entered.connect(_on_hovered)
	area_2d.mouse_exited.connect(_on_hovered_off)
	CardManager.connect_card_signals(self)
	play_flip_anim()

func is_interactable() -> bool:
	return !(is_draging or is_in_slot or CardManager.card_being_dragged or is_player_card)

func _on_hovered():
	if !is_interactable():return 
	highlight_card(true)
	on_hovered.emit(self)
	
func _on_hovered_off():
	if !is_interactable():return 
	highlight_card(false)
	on_hovered_off.emit(self)


func highlight_card(hovered):
	if hovered:
		self.scale = Vector2(1.1, 1.1)
		self.z_index = 2
	else:
		self.scale = Vector2(1, 1)
		self.z_index = 1


func set_in_slot(state:bool):
	is_in_slot = state
	collision_shape_2d.disabled = state
	self.scale = Vector2(.9, .9) if state else Vector2(1,1)
	self.z_index = 1

func start_drag(state : bool):
	self.is_draging = state
	self.scale = Vector2(1,1)  if state else Vector2(1,1)


func update_visual():
	if not card_data:
		return
	display_image.texture = load(self.card_data.texture_path)
	atk.text = str(card_data.atk)
	def.text = str(card_data.def)
	self.name = card_data.card_name
	

func play_flip_anim():
	animation_player.play("card_flip")
