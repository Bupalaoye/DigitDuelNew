extends  Node
# 卡牌花色定义
const SUITS = [
	'hearts',
	'spades',
	'diamonds',
	'clubs'
]

# 卡牌牌面值定义
const CARD_DEFINITIONS = {
	'2': {'name': 'Two', 'value': 2, 'description': 'The lowest card in the deck.'},
	'3': {'name': 'Three', 'value': 3, 'description': 'A low card, but higher than a two.'},
	'4': {'name': 'Four', 'value': 4, 'description': 'A mid-low card.'},
	'5': {'name': 'Five', 'value': 5, 'description': 'A mid-range card.'},
	'6': {'name': 'Six', 'value': 6, 'description': 'A solid mid-range card.'},
	'7': {'name': 'Seven', 'value': 7, 'description': 'A good card for many hands.'},
	'8': {'name': 'Eight', 'value': 8, 'description': 'A strong mid-range card.'},
	'9': {'name': 'Nine', 'value': 9, 'description': 'Approaching the high end of the range.'},
	'10': {'name': 'Ten', 'value': 10, 'description': 'A high card, often used to win hands.'},
	'jack': {'name': 'Jack', 'value': 11, 'description': 'A face card, valuable in many games.'},
	'queen': {'name': 'Queen', 'value': 12, 'description': 'A powerful face card.'},
	'king': {'name': 'King', 'value': 13, 'description': 'The second highest face card.'},
	'ace': {'name': 'Ace', 'value': 14, 'description': 'The highest card, can be low or high depending on the game.'}
}

# 特殊卡牌定义 (大小王)
const JOKER_DEFINITIONS = {
	'joker_red': {'name': 'Joker', 'value': 15, 'color': 'red', 'description': 'A special card that can be the highest value or a wild card.'},
	'joker_black': {'name': 'Joker', 'value': 15, 'color': 'black', 'description': 'A special card that can be the highest value or a wild card.'}
}


# 生成所有标准卡牌资源文件名的数组
func get_card_asset_names() -> Array[String]:
	var asset_names: Array[String] = []
	# 遍历所有花色
	for suit in SUITS:
		# 遍历所有牌面值
		for rank in CARD_DEFINITIONS.keys():
			# 组合成文件名并添加到数组中
			asset_names.append("%s_of_%s" % [rank, suit])
	# 添加大小王的文件名
	asset_names.append_array(JOKER_DEFINITIONS.keys())
	# 返回所有卡牌的资源文件名数组
	return asset_names
