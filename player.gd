extends CharacterBody3D

var velocity_last_frame: Vector2 #存储上一帧的水平移动速度(用于跳跃)
var sprint_flag = false #疾跑标志位
var crouch_flag = false #下蹲标志位
var flashl_flag = false #头灯标志位
var xAxis:float
var yAxis:float
const Min_Camera_Angle = -1.3 #相机的最小俯角
const Max_Camera_Angle = 1.3 #相机的最大仰角
const Max_FallingSpeed = -210.0 #最大下落速度

@onready var CamHead = get_node("CamPivot") #使用另一个节点控制相机的俯仰，避免万向节锁死或旋转顺序错误
@onready var FlashL = get_node("CamPivot/SpotLight3D") #控制手电的开关
@export var Move_Speed = 4.7 #移动速度
@export var Sprint_Speed = 7.9 #疾跑速度
@export var Air_Speed =  1.6 #空中速度
@export var Jump_Force = 9.7 #跳跃力度
@export var Acceleration = 8.4 #移动加速度
@export var Air_Accel = 0.6 #玩家自身的空气阻力系数(只计算水平阻力)

#将输入事件归类作初步整理
func _unhandled_input(event):
	if event is InputEventMouseMotion: #处理相机旋转和输入设备切换
		PlayerControlGlobal.Input_Flag = 1 #模式为键鼠模式
		PlayerControlGlobal.DeviceID = event.device #设置设备ID，目前未使用，若需添加双人分屏则可用
		_handle_mouse_camera_rotation(event) #根据鼠标移动旋转相机
	elif event is InputEventKey: #键盘按下
		PlayerControlGlobal.DeviceID = event.device 
		PlayerControlGlobal.Input_Flag = 1
		_handle_key_input() #处理键盘事件
	elif event is InputEventJoypadMotion: #手柄摇杆触动，由于手柄视角控制的特殊性，需要在_physics_process(delta)中处理
		PlayerControlGlobal.DeviceID = event.device
		xAxis = Input.get_joy_axis(PlayerControlGlobal.DeviceID,JOY_AXIS_LEFT_X) + Input.get_joy_axis(PlayerControlGlobal.DeviceID,JOY_AXIS_RIGHT_X)
		yAxis = Input.get_joy_axis(PlayerControlGlobal.DeviceID,JOY_AXIS_LEFT_Y) + Input.get_joy_axis(PlayerControlGlobal.DeviceID,JOY_AXIS_RIGHT_Y)
		if (abs(xAxis) > PlayerControlGlobal.Dead_Zone * 2) or (abs(yAxis) > PlayerControlGlobal.Dead_Zone * 2):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			PlayerControlGlobal.GamePad_Name = Input.get_joy_name(event.device) #获得手柄名称
			if PlayerControlGlobal.GamePad_Name == "XInput Gamepad": #Xbox手柄
				PlayerControlGlobal.Input_Flag = 2
			elif PlayerControlGlobal.GamePad_Name == "Nintendo Switch Pro Controller": #Switch的Pro手柄
				PlayerControlGlobal.Input_Flag = 4
			else:
				PlayerControlGlobal.Input_Flag = 3 #Sony手柄
	elif event is InputEventJoypadButton: #手柄按键按下
		PlayerControlGlobal.DeviceID = event.device
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		PlayerControlGlobal.GamePad_Name = Input.get_joy_name(event.device)
		if PlayerControlGlobal.GamePad_Name == "XInput Gamepad": #Xbox手柄
			PlayerControlGlobal.Input_Flag = 2
		elif PlayerControlGlobal.GamePad_Name == "Nintendo Switch Pro Controller": #Switch的Pro手柄
			PlayerControlGlobal.Input_Flag = 4
		else:
			PlayerControlGlobal.Input_Flag = 3 #Sony手柄，我没有dual sense不知道引擎内部用的什么名称，需要的可以自行测试或查阅引擎源码
		_handle_gamepad_button()
	elif event is InputEventMouseButton: #鼠标按键按下
		PlayerControlGlobal.DeviceID = event.device
		PlayerControlGlobal.Input_Flag = 1

#键鼠部分开始
func _handle_mouse_camera_rotation(event): #处理鼠标输入的相机旋转
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED #捕获并隐藏光标
	rotate_y(deg_to_rad(-event.relative.x * PlayerControlGlobal.Mouse_Sensity * 0.5)) #沿y轴旋转角色
	CamHead.rotate_x(deg_to_rad(event.relative.y * PlayerControlGlobal.Mouse_Sensity * PlayerControlGlobal.Reverse_YAxis * 0.5)) #旋转头部而非相机
	CamHead.rotation.x = clamp(CamHead.rotation.x, Min_Camera_Angle, Max_Camera_Angle) #限制相机俯仰角

func _handle_key_input(): #处理键盘事件
	if Input.is_action_pressed("Sprint"): #疾跑
		if sprint_flag == false and crouch_flag == false:
			sprint_flag = true
		else:
			sprint_flag = false

	if Input.is_action_pressed("UseFlashLight"):
		if flashl_flag == false:
			FlashL.show()
			flashl_flag = true
		else:
			FlashL.hide()
			flashl_flag = false
#键鼠部分结束

#手柄部分开始
func _handle_joystick_camera_rotation(ID): #处理摇杆相机旋转，由于操作特殊性需要在_physics_process(delta)中调用
	xAxis = Input.get_joy_axis(ID, JOY_AXIS_RIGHT_X) #赋值摇杆推拉数据
	yAxis = Input.get_joy_axis(ID, JOY_AXIS_RIGHT_Y)
	if PlayerControlGlobal.Input_Flag > 1 and (abs(xAxis) > PlayerControlGlobal.Dead_Zone or abs(yAxis) > PlayerControlGlobal.Dead_Zone): 
		rotate_y(-xAxis * PlayerControlGlobal.Joystiock_Sensity)
		CamHead.rotate_x(yAxis * PlayerControlGlobal.Joystiock_Sensity * PlayerControlGlobal.Reverse_YAxis)
		CamHead.rotation.x = clamp(CamHead.rotation.x, Min_Camera_Angle, Max_Camera_Angle)

func _handle_gamepad_button(): 
	if Input.is_action_pressed("Sprint"): #疾跑
		if sprint_flag == false:
			sprint_flag = true
		else:
			sprint_flag = false

	if Input.is_action_pressed("UseFlashLight"):
		if flashl_flag == false:
			FlashL.show()
			flashl_flag = true
		else:
			FlashL.hide()
			flashl_flag = false
#手柄部分结束

func _physics_process(delta): #每帧运行一次，delta等于当前帧的生成时间，用于校正
	var direction = Vector3.ZERO #声明方向矢量并归零
	_handle_joystick_camera_rotation(PlayerControlGlobal.DeviceID) #处理摇杆的相机旋转
	
	#根据输入和状态生成运动矢量方向 开始
	if PlayerControlGlobal.Input_Flag == 1: #键鼠，输入为整数
		direction = Input.get_vector("Motion_Leftward", "Motion_Rightward", "Motion_Forward", "Motion_Backward")
		direction = (transform.basis * Vector3(direction.x, 0, direction.y)).normalized() #方向矢量归一化，避免斜向移动被加速
	elif PlayerControlGlobal.Input_Flag > 1: #手柄，输入为浮点
		direction.x = Input.get_axis("Motion_Leftward", "Motion_Rightward")
		direction.y = Input.get_axis("Motion_Forward", "Motion_Backward")
		if direction.length() > 1.0:
			direction = direction.normalized() #避免手柄在部分区间输入大于1
		direction = (transform.basis * Vector3(direction.x, 0, direction.y))
	#根据输入和状态生成运动矢量方向 结束
	
	if Input.is_action_pressed("Jump") and is_on_floor() and PlayerControlGlobal.Press_Captured == false: #跳跃
		PlayerControlGlobal.Press_Captured = true
		velocity.y += Jump_Force
	if Input.is_action_just_released("Jump"):
		PlayerControlGlobal.Press_Captured = false
	
	if is_on_floor() and PlayerControlGlobal: #地面
		if sprint_flag == false:
			velocity.x = lerp(velocity.x, direction.x * Move_Speed, Acceleration * delta) #使用加速度控制速度
			velocity.z = lerp(velocity.z, direction.z * Move_Speed, Acceleration * delta)
		else:
			velocity.x = lerp(velocity.x, direction.x * Sprint_Speed, Acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * Sprint_Speed, Acceleration * delta)
	elif PlayerControlGlobal: #空中
		velocity.z = lerp(velocity_last_frame.y, direction.z * Air_Speed, Air_Accel * delta) #控制减弱
		velocity.x = lerp(velocity_last_frame.x, direction.x * Air_Speed, Air_Accel * delta)
	
	if velocity.length() <= 3.0:
		sprint_flag = false
	
	velocity_last_frame = Vector2(velocity.x, velocity.z) #储存当前帧的水平速度
	velocity.y = lerp(velocity.y, Max_FallingSpeed, PlayerControlGlobal.GlobalGravity * delta * 0.013) #重力影响，默认的重力太大了
	move_and_slide()
