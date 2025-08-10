# GridPlacement.gd
extends Node2D

# --- 布局参数 ---
@export_group("Grid Layout")
@export var columns: int = 5
@export var card_width: float = 52
@export var card_height: float = 77
@export var h_spacing: float = 20.0 # 水平间距
@export var v_spacing: float = 15.0 # 区域内的垂直间距

@export_group("Player/Opponent Setup")
@export var slots_per_player: int = 10
@export var center_divider_spacing: float = 50.0 # 对手和玩家区域之间的“分界线”间距

# --- 资源预加载 ---
const CARD_SLOT = preload("uid://beayidfusy8gk")

# --- 内部变量 ---
var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport_rect().size
	# 清理旧的slots，防止重复生成
	for child in get_children():
		child.queue_free()
	
	generate_all_slots()

func generate_all_slots() -> void:
	# --- 1. 计算整体布局尺寸 ---
	
	# 每个玩家区域有多少行
	var rows_per_player = ceil(float(slots_per_player) / columns)
	
	# 计算网格的总宽度 (这个对两个区域都一样)
	var total_grid_width = (columns * card_width) + ((columns - 1) * h_spacing)
	
	# 计算每个玩家区域的总高度
	var player_area_height = (rows_per_player * card_height) + ((rows_per_player - 1) * v_spacing)
	
	# 计算包含分界线的总高度
	var total_height = (player_area_height * 2) + center_divider_spacing
	
	# --- 2. 计算起始坐标 ---
	
	# 网格块的起始X坐标 (使其水平居中)
	var start_x = (screen_size.x - total_grid_width) / 2.0
	
	# 整个布局块的起始Y坐标 (使其垂直居中)
	var start_y = (screen_size.y - total_height) / 2.0
	
	# --- 3. 生成卡槽 ---
	
	# A. 生成对手的卡槽 (前20个)
	var opponent_start_y = start_y
	generate_slots_for_area(slots_per_player, start_x, opponent_start_y, false)
	
	# B. 生成玩家的卡槽 (后20个)
	# 玩家区域的起始Y坐标 = 对手区域的起始Y + 对手区域的高度 + 分界线间距
	var player_start_y = opponent_start_y + player_area_height + center_divider_spacing
	generate_slots_for_area(slots_per_player, start_x, player_start_y, true)


# 专门用于生成一个区域内卡槽的函数
func generate_slots_for_area(num_slots: int, area_start_x: float, area_start_y: float, owner_is_player: bool) -> void:
	for i in range(num_slots):
		var card_slot = CARD_SLOT.instantiate()
		add_child(card_slot)
		
		# (可选) 可以给卡槽添加元数据，方便以后识别
		card_slot.owner_is_player = owner_is_player
		card_slot.z_index = -1
		
		# 计算在当前区域内的行列索引
		var col = i % columns
		var row = i / columns
		
		# 计算卡槽的中心点坐标
		var slot_center_x = area_start_x + (col * (card_width + h_spacing)) + (card_width / 2.0)
		var slot_center_y = area_start_y + (row * (card_height + v_spacing)) + (card_height / 2.0)
		
		# 设置位置
		# 我们已经知道它是 Node2D, 可以简化判断
		card_slot.position = Vector2(slot_center_x, slot_center_y)
