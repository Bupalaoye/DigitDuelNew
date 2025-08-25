extends Camera2D

var starting_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	self.starting_offset = self.offset

func shake_camera(amount: float, duration: float):
	var update_shake_offset = func(shake_amount: float):
		self.offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))

	var tween = get_tree().create_tween()
	# 使用随机数模拟不规则震动
	tween.tween_method(update_shake_offset, amount, 0.0, duration).set_trans(Tween.TRANS_SINE)

	# 确保镜头最后回到原位
	await tween.finished
	self.offset = self.starting_offset
