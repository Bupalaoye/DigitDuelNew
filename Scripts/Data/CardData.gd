extends Resource

class_name CardData

# --- 卡牌属性 ---

@export var card_id: StringName = &""  # 卡牌的唯一ID, 例如: "ace_of_spades", "joker_red"
@export var card_name: String = ""     # 用于显示的卡牌名称, 例如: "Ace", "Joker"


@export_group("prop")
# 遵循GDScript风格，属性名建议使用小写蛇形命名法 (snake_case)
@export var cost: int = 0
@export var atk: int = 0
@export var def: int = 0

@export_group("visual")
# 我们也可以把图片路径存在这里！
@export var texture_path: String = "" 

@export_group("desc")
@export var description: String = ""   # 卡牌描述
@export var rules_text : String = ""
@export var flavor_text : String = ""
