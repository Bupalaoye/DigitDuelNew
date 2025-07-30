extends Node2D


var starting_position := Vector2(0, 0)

@onready var area_2d: Area2D = %Area2D

signal on_hovered
signal on_hovered_off

func _ready() -> void:
	area_2d.mouse_entered.connect(_on_hovered)
	area_2d.mouse_exited.connect(_on_hovered_off)
	CardManager.connect_card_signals(self)


func _on_hovered():
	on_hovered.emit(self)
	
func _on_hovered_off():
	on_hovered_off.emit(self)
