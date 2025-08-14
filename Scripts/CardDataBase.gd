extends Node

# 这个字典将作为缓存，映射卡牌ID字符串到其已加载的CardData资源。
# 这样可以确保每个资源文件只被加载一次。
var _card_data_cache: Dictionary = {}

# 这个字典将存储我们所有.tres文件的路径。
# 我们会在游戏启动时填充它。
var _card_resource_paths: Dictionary = {}


func _ready():
	# 游戏启动时，自动扫描指定目录下的所有卡牌数据文件
	_populate_resource_paths("res://CardData/")


## 填充内部字典，包含所有CardData资源的路径。
func _populate_resource_paths(directory: String):
	var dir = DirAccess.open(directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# 确保我们只处理.tres文件，并且它不是一个目录
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				# 从文件名中提取ID (例如, "ace_of_spades.tres" -> "ace_of_spades")
				var card_id = file_name.get_basename()
				_card_resource_paths[card_id] = dir.get_current_dir().path_join(file_name)
			file_name = dir.get_next()
	else:
		push_error("CardDataBase: 无法打开目录: " + directory)


## 返回一个包含所有已知卡牌ID的数组 (例如, ["ace_of_spades", "king_of_hearts", ...])。
## 这个函数替代了您旧的 get_card_asset_names()。
func get_all_card_ids() -> Array:
	return _card_resource_paths.keys()


## 获取特定卡牌数据的主函数。
## 如果数据不在缓存中，它会从磁盘加载资源。
func get_card_data(card_id: String) -> CardData:
	# 1. 检查数据是否已在缓存中。
	if _card_data_cache.has(card_id):
		return _card_data_cache[card_id]
		
	# 2. 检查我们是否有这张卡牌的路径。
	if not _card_resource_paths.has(card_id):
		push_error("找不到ID为 '%s' 的卡牌数据" % card_id)
		return null
		
	# 3. 从路径加载资源。
	var card_resource: CardData = load(_card_resource_paths[card_id])
	
	if card_resource:
		# 4. 将加载的资源存入缓存，以便下次快速访问。
		_card_data_cache[card_id] = card_resource
		return card_resource
	else:
		push_error("加载卡牌资源失败，路径: " + _card_resource_paths[card_id])
		return null
