extends Node

@export var GlobalGravity: float #默认重力
@export var Mouse_Sensity = 0.20 #鼠标灵敏度
@export var Joystiock_Sensity = 0.07 #手柄灵敏度
@export var Dead_Zone = 0.15 #摇杆死区

var Input_Flag = 1 #定义输入模式，1为鼠标键盘，2为Xbox手柄，3为PS手柄，4为Switch手柄
var Devices: PackedInt32Array #用于获取所有输入设备的id
var GamePad_Name: String #用于获得手柄名称
var DeviceID = 0 #存储激活的输入设备ID
var menu_level = 0 #菜单层级，最后一级为0
var screen_res:Vector2 #声明屏幕分辨率向量
var Press_Captured = false #用于按键捕获标志，防止一次按键多次处理
var Reverse_YAxis = -1 #是否反转Y轴控制，否为-1，是为1

func _ready():
	GlobalGravity = ProjectSettings.get_setting("physics/3d/default_gravity") #获取重力
