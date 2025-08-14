@tool # <-- 这是最关键的部分！它告诉Godot这个脚本可以在编辑器中运行。
extends EditorScript

# --- 配置 ---
# 定义CardData脚本的路径和输出目录
const CARD_DATA_PATH = "res://Scripts/Data/CardData.gd"
const OUTPUT_DIRECTORY = "res://CardData/"

# --- 数据源 (我们直接从旧脚本中复制过来) ---
const SUITS = ['hearts', 'spades', 'diamonds', 'clubs']

const CARD_DEFINITIONS = {
	'2': {'name': 'Two', 'atk': 2, 'def': 2, 'description': 'The lowest card in the deck.'},
	'3': {'name': 'Three', 'atk': 3, 'def': 3, 'description': 'A low card, but higher than a two.'},
	'4': {'name': 'Four', 'atk': 4, 'def': 4, 'description': 'A mid-low card.'},
	'5': {'name': 'Five', 'atk': 5, 'def': 5, 'description': 'A mid-range card.'},
	'6': {'name': 'Six', 'atk': 6, 'def': 6, 'description': 'A solid mid-range card.'},
	'7': {'name': 'Seven', 'atk': 7, 'def': 7, 'description': 'A good card for many hands.'},
	'8': {'name': 'Eight', 'atk': 8, 'def': 8, 'description': 'A strong mid-range card.'},
	'9': {'name': 'Nine', 'atk': 9, 'def': 9, 'description': 'Approaching the high end of the range.'},
	'10': {'name': 'Ten', 'atk': 10, 'def': 10, 'description': 'A high card, often used to win hands.'},
	'jack': {'name': 'Jack', 'atk': 11, 'def': 11, 'description': 'A face card, valuable in many games.'},
	'queen': {'name': 'Queen', 'atk': 12, 'def': 12, 'description': 'A powerful face card.'},
	'king': {'name': 'King', 'atk': 13, 'def': 13, 'description': 'The second highest face card.'},
	'ace': {'name': 'Ace', 'atk': 14, 'def': 14, 'description': 'The highest card, can be low or high depending on the game.'}
}

const JOKER_DEFINITIONS = {
	'joker_red': {'name': 'Joker', 'atk': 15, 'def': 15, 'color': 'red', 'description': 'A special card that can be the highest value or a wild card.'},
	'joker_black': {'name': 'Joker', 'atk': 15, 'def': 15, 'color': 'black', 'description': 'A special card that can be the highest value or a wild card.'}
}


# EditorScript的入口函数
func _run():
	# 检查并创建输出目录
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	
	print("--- 开始批量生成卡牌资源 ---")
	
	# 加载CardData模板资源
	var card_data_template = load(CARD_DATA_PATH)
	if not card_data_template:
		push_error("无法加载CardData模板，请检查路径: " + CARD_DATA_PATH)
		return

	# 1. 生成所有标准卡牌
	for suit in SUITS:
		for rank in CARD_DEFINITIONS.keys():
			var data = CARD_DEFINITIONS[rank]
			var card_id = "%s_of_%s" % [rank, suit]
			
			var card_resource = card_data_template.new() # 创建一个新的CardData实例
			
			# 填充数据
			card_resource.card_id = card_id
			card_resource.card_name = data.name
			card_resource.description = data.description
			card_resource.atk = data.atk
			card_resource.def = data.def
			card_resource.suit = suit
			card_resource.rank = rank
			card_resource.texture_path = "res://PlayingCards/individual_sprites/%s.png" % card_id
			
			# 保存为.tres文件
			var save_path = OUTPUT_DIRECTORY.path_join(card_id + ".tres")
			var error = ResourceSaver.save(card_resource, save_path)
			
			if error == OK:
				print("成功生成: " + save_path)
			else:
				push_error("生成失败: " + save_path)

	# 2. 生成大小王
	for rank in JOKER_DEFINITIONS.keys():
		var data = JOKER_DEFINITIONS[rank]
		var card_id = rank # joker_red, joker_black
		
		var card_resource = card_data_template.new()
		
		# 填充数据
		card_resource.card_id = card_id
		card_resource.card_name = data.name
		card_resource.description = data.description
		card_resource.atk = data.atk
		card_resource.def = data.def
		card_resource.suit = "joker" # 或者留空
		card_resource.rank = rank
		card_resource.texture_path = "res://PlayingCards/individual_sprites/%s.png" % card_id

		# 保存为.tres文件
		var save_path = OUTPUT_DIRECTORY.path_join(card_id + ".tres")
		var error = ResourceSaver.save(card_resource, save_path)
		
		if error == OK:
			print("成功生成: " + save_path)
		else:
			push_error("生成失败: " + save_path)
			
	print("--- 批量生成完成！ ---")
