-- 车辆控制菜单状态
local isInVehControl = false
-- 车窗状态 (true = 关闭, false = 打开)
local windowState1 = true  -- 前左车窗
local windowState2 = true  -- 前右车窗
local windowState3 = true  -- 后左车窗
local windowState4 = true  -- 后右车窗

-- 主循环线程
Citizen.CreateThread(function()
    while true do
		Citizen.Wait(0)
		-- 已禁用：离开时保持引擎运行功能（使用其他插件）
		--[[
		if LeaveRunning then
			local playerPed = GetPlayerPed(-1)
			local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
			-- 检测是否在车辆中且长按F键(控制ID 75)
			if IsPedInAnyVehicle(playerPed, false) and IsControlPressed(2, 75) and not IsEntityDead(playerPed) then
                Citizen.Wait(150)
				-- 再次确认，防止误触
				if IsPedInAnyVehicle(playerPed, false) and IsControlPressed(2, 75) and not IsEntityDead(playerPed) then
					-- 保持引擎运行并离开车辆
					SetVehicleEngineOn(vehicle, true, true, false)
					TaskLeaveVehicle(playerPed, vehicle, 0)
				end
			end
		end
		--]]
		
		-- 如果启用了禁用座位自动切换功能
		if IsPedInAnyVehicle(GetPlayerPed(-1), false) and DisableSeatShuffle then
			local playerPed = GetPlayerPed(-1)
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			-- 检查玩家是否在驾驶座(座位-1，不是0)
			if GetPedInVehicleSeat(vehicle, -1) == playerPed then
				-- 如果检测到自动换座任务(任务ID 165)，强制保持在驾驶座
				-- 这只会阻止从驾驶座意外换到其他位置，不会阻止从其他位置换到驾驶座
				if GetIsTaskActive(playerPed, 165) then
					SetPedIntoVehicle(playerPed, vehicle, -1)
				end
			end
		end
		
		-- Z键切换座位功能已通过RegisterKeyMapping注册，无需在此检测
    end
end)

-----------------------------------------------------------------------------
-- NUI 打开导出/事件
-----------------------------------------------------------------------------

-- 注册车辆控制命令
RegisterCommand("vehcontrol", function(source, args, rawCommand)
	-- 检查玩家是否在车辆中且游戏未暂停
	if IsPedInAnyVehicle(PlayerPedId(), false) and not IsPauseMenuActive() then
		openVehControl()
	end
end, false)

-- 注册按键映射
RegisterKeyMapping('vehcontrol', '打开车辆菜单', 'keyboard', DefaultOpen)

-- 注册Z键切换座位命令
RegisterCommand("cycleseat", function(source, args, rawCommand)
	if EnableSeatCycle and IsPedInAnyVehicle(PlayerPedId(), false) then
		CycleSeat()
	end
end, false)

-- 注册Z键映射（仅在启用时注册）
if EnableSeatCycle then
	RegisterKeyMapping('cycleseat', '切换座位', 'keyboard', 'Z')
end

-- 外部打开函数(供其他脚本调用)
function openExternal()
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		openVehControl()
	end
end

-- 注册网络事件，允许服务器端触发打开菜单
RegisterNetEvent('vehcontrol:openExternal')
AddEventHandler('vehcontrol:openExternal', function()
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		openVehControl()
	end
end)

-----------------------------------------------------------------------------
-- NUI 打开/关闭函数
-----------------------------------------------------------------------------

-- 打开车辆控制菜单
function openVehControl()
	isInVehControl = true
	SetNuiFocus(true, true)  -- 启用NUI焦点，允许鼠标操作
	SendNUIMessage({
		type = "openGeneral"
	})
end

-- 关闭车辆控制菜单
function closeVehControl()
	isInVehControl = false
	SetNuiFocus(false, false)  -- 禁用NUI焦点
	SendNUIMessage({
		type = "closeAll"
	})
end

-- NUI回调：失去焦点时关闭菜单
RegisterNUICallback('NUIFocusOff', function()
	isInVehControl = false
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "closeAll"
	})
end)

-----------------------------------------------------------------------------
-- NUI 回调函数
-----------------------------------------------------------------------------

-- 点火开关回调
RegisterNUICallback('ignition', function()
    EngineControl()
end)

-- 车内灯控制回调
RegisterNUICallback('interiorLight', function()
	InteriorLightControl()
end)

-- 车门控制回调
RegisterNUICallback('doors', function(data, cb)
	DoorControl(data.door)
end)

-- 座位切换回调
RegisterNUICallback('seatchange', function(data, cb)
	SeatControl(data.seat)
end)

-- 车窗控制回调
RegisterNUICallback('windows', function(data, cb)
	WindowControl(data.window, data.door)
end)

-- 炸弹舱门控制回调
RegisterNUICallback('bombbay', function()
	BombBayControl()
end)

-----------------------------------------------------------------------------
-- 功能控制函数
-----------------------------------------------------------------------------

-- 引擎控制函数 - 切换引擎开关状态
function EngineControl()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    -- 检查车辆有效且玩家在驾驶座
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
        -- 切换引擎状态(如果运行则关闭，如果关闭则启动)
        SetVehicleEngineOn(vehicle, (not GetIsVehicleEngineRunning(vehicle)), false, true)
    end
end

-- 车内灯控制函数 - 切换车内灯开关
function InteriorLightControl()
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 如果灯开着则关闭，如果关着则打开
		if IsVehicleInteriorLightOn(vehicle) then
			SetVehicleInteriorlight(vehicle, false)
		else
			SetVehicleInteriorlight(vehicle, true)
		end
	end
end

-- 车门控制函数 - 开关指定车门
-- door: 车门ID (0=前左, 1=前右, 2=后左, 3=后右, 4=引擎盖, 5=后备箱, 6=后备箱2)
function DoorControl(door)
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 如果门开着则关闭，如果关着则打开
		if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
			SetVehicleDoorShut(vehicle, door, false)
		else
			SetVehicleDoorOpen(vehicle, door, false)
		end
	end
end

-- 座位控制函数 - 切换到指定座位
-- seat: 座位ID (-1=驾驶座, 0=副驾驶, 1=后左, 2=后右)
function SeatControl(seat)
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 如果座位空闲则切换过去
		if IsVehicleSeatFree(vehicle, seat) then
			SetPedIntoVehicle(GetPlayerPed(-1), vehicle, seat)
		end
	end
end

-- 带动画的切换座位函数
function SwitchSeatWithAnimation(playerPed, vehicle, targetSeat)
	-- 直接使用SetPedIntoVehicle确保玩家始终在车内（不会下车）
	-- 注意：在GTA V/FiveM中，要在车内切换座位且有动画但不下车在技术上很困难
	-- TaskWarpPedIntoVehicle在某些情况下会导致玩家先离开车辆
	-- 为了确保玩家不会下车，使用SetPedIntoVehicle进行直接切换
	SetPedIntoVehicle(playerPed, vehicle, targetSeat)
end

-- 循环切换座位函数 - 按Z键时切换座位
function CycleSeat()
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local currentSeat = -2  -- 初始化为无效值
		
		-- 查找当前所在座位（检查所有座位）
		for seat = -1, 2 do
			if GetPedInVehicleSeat(vehicle, seat) == playerPed then
				currentSeat = seat
				break
			end
		end
		
		-- 如果找不到当前座位，退出
		if currentSeat == -2 then
			return
		end
		
		-- 根据配置决定座位顺序
		local seatOrder = {}
		if SeatCycleOnlyFront then
			-- 只在驾驶座和副驾驶之间切换
			seatOrder = {-1, 0}
		else
			-- 可以在所有座位之间切换
			seatOrder = {-1, 0, 1, 2}
		end
		
		-- 如果当前座位不在切换列表中，优先切换到驾驶座或副驾驶
		local inOrder = false
		for i, seat in ipairs(seatOrder) do
			if seat == currentSeat then
				inOrder = true
				break
			end
		end
		
		-- 如果当前座位不在切换列表中（比如在后座），优先切换到驾驶座或副驾驶
		if not inOrder then
			if IsVehicleSeatFree(vehicle, -1) then
				SwitchSeatWithAnimation(playerPed, vehicle, -1)
			elseif IsVehicleSeatFree(vehicle, 0) then
				SwitchSeatWithAnimation(playerPed, vehicle, 0)
			end
			return
		end
		
		-- 找到当前座位在顺序中的位置
		local currentIndex = 1
		for i, seat in ipairs(seatOrder) do
			if seat == currentSeat then
				currentIndex = i
				break
			end
		end
		
		-- 尝试切换到下一个座位（循环）
		for i = 1, #seatOrder do
			local nextIndex = (currentIndex + i - 1) % #seatOrder + 1
			local trySeat = seatOrder[nextIndex]
			
			-- 如果目标座位空闲且不是当前座位，则切换
			if trySeat ~= currentSeat and IsVehicleSeatFree(vehicle, trySeat) then
				SwitchSeatWithAnimation(playerPed, vehicle, trySeat)
				break
			end
		end
	end
end

-- 车窗控制函数 - 开关指定车窗
-- window: 车窗ID (0=前左, 1=前右, 2=后左, 3=后右)
-- door: 对应的车门ID
function WindowControl(window, door)
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 前左车窗 (window 0)
		if window == 0 then
			if windowState1 == true and DoesVehicleHaveDoor(vehicle, door) then
				RollDownWindow(vehicle, window)  -- 降下车窗
				windowState1 = false
			else
				RollUpWindow(vehicle, window)  -- 升起车窗
				windowState1 = true
			end
		-- 前右车窗 (window 1)
		elseif window == 1 then
			if windowState2 == true and DoesVehicleHaveDoor(vehicle, door) then
				RollDownWindow(vehicle, window)
				windowState2 = false
			else
				RollUpWindow(vehicle, window)
				windowState2 = true
			end
		-- 后左车窗 (window 2)
		elseif window == 2 then
			if windowState3 == true and DoesVehicleHaveDoor(vehicle, door) then
				RollDownWindow(vehicle, window)
				windowState3 = false
			else
				RollUpWindow(vehicle, window)
				windowState3 = true
			end
		-- 后右车窗 (window 3)
		elseif window == 3 then
			if windowState4 == true and DoesVehicleHaveDoor(vehicle, door) then
				RollDownWindow(vehicle, window)
				windowState4 = false
			else
				RollUpWindow(vehicle, window)
				windowState4 = true
			end
		end
	end
end

-- 前车窗控制函数 - 同时控制前左和前右车窗
function FrontWindowControl()
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 如果任一前车窗关闭，则全部降下
		if windowState1 == true or windowState2 == true then
			RollDownWindow(vehicle, 0)
			RollDownWindow(vehicle, 1)
			windowState1 = false
			windowState2 = false
		else
			-- 否则全部升起
			RollUpWindow(vehicle, 0)
			RollUpWindow(vehicle, 1)
			windowState1 = true
			windowState2 = true
		end
	end
end

-- 后车窗控制函数 - 同时控制后左和后右车窗
function BackWindowControl()
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 如果任一后车窗关闭，则全部降下
		if windowState3 == true or windowState4 == true then
			RollDownWindow(vehicle, 2)
			RollDownWindow(vehicle, 3)
			windowState3 = false
			windowState4 = false
		else
			-- 否则全部升起
			RollUpWindow(vehicle, 2)
			RollUpWindow(vehicle, 3)
			windowState3 = true
			windowState4 = true
		end
	end
end

-- 全部车窗控制函数 - 同时控制所有车窗
function AllWindowControl()
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 如果任一车窗关闭，则全部降下
		if windowState1 == true or windowState2 == true or windowState3 == true or windowState4 == true then
			RollDownWindow(vehicle, 0)
			RollDownWindow(vehicle, 1)
			RollDownWindow(vehicle, 2)
			RollDownWindow(vehicle, 3)
			windowState1 = false
			windowState2 = false
			windowState3 = false
			windowState4 = false
		else
			-- 否则全部升起
			RollUpWindow(vehicle, 0)
			RollUpWindow(vehicle, 1)
			RollUpWindow(vehicle, 2)
			RollUpWindow(vehicle, 3)
			windowState1 = true
			windowState2 = true
			windowState3 = true
			windowState4 = true
		end
	end
end

-- 炸弹舱门控制函数 - 开关炸弹舱门(适用于飞机等载具)
function BombBayControl()
	local playerPed = GetPlayerPed(-1)
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		-- 如果舱门开着则关闭，如果关着则打开
		if AreBombBayDoorsOpen(vehicle) then
			CloseBombBayDoors(vehicle)
		else
			OpenBombBayDoors(vehicle)
		end
	end
end

-----------------------------------------------------------------------------
-- 车辆命令系统
-----------------------------------------------------------------------------
if UseCommands then
	-- 引擎命令
	TriggerEvent('chat:addSuggestion', '/engine', '启动/关闭引擎')

	RegisterCommand("engine", function(source, args, rawCommand)
		EngineControl()
	end, false)

	-- 车门命令
	TriggerEvent('chat:addSuggestion', '/door', '打开/关闭车门', {
		{ name="ID", help="1) 驾驶座, 2) 副驾驶, 3) 后左座, 4) 后右座" }
	})

	RegisterCommand("door", function(source, args, rawCommand)
		local doorID = tonumber(args[1])
		if doorID ~= nil then
			if doorID == 1 then
				DoorControl(0)  -- 驾驶座车门
			elseif doorID == 2 then
				DoorControl(1)  -- 副驾驶车门
			elseif doorID == 3 then
				DoorControl(2)  -- 后左车门
			elseif doorID == 4 then
				DoorControl(3)  -- 后右车门
			end
		else
			TriggerEvent("chatMessage", "用法: ", {255, 0, 0}, "/door [车门ID]")
		end
	end, false)

	-- 座位命令
	TriggerEvent('chat:addSuggestion', '/seat', '切换到指定座位', {
		{ name="ID", help="1) 驾驶座, 2) 副驾驶, 3) 后左座, 4) 后右座" }
	})

	RegisterCommand("seat", function(source, args, rawCommand)
		local seatID = tonumber(args[1])
		if seatID ~= nil then
			if seatID == 1 then
				SeatControl(-1)  -- 驾驶座
			elseif seatID == 2 then
				SeatControl(0)  -- 副驾驶
			elseif seatID == 3 then
				SeatControl(1)  -- 后左座
			elseif seatID == 4 then
				SeatControl(2)  -- 后右座
			end
		else
			TriggerEvent("chatMessage", "用法: ", {255, 0, 0}, "/seat [座位ID]")
		end
	end, false)

	-- 车窗命令
	TriggerEvent('chat:addSuggestion', '/window', '升起/降下车窗', {
		{ name="ID", help="1) 驾驶座, 2) 副驾驶, 3) 后左座, 4) 后右座" }
	})

	RegisterCommand("window", function(source, args, rawCommand)
		local windowID = tonumber(args[1])
		
		if windowID ~= nil then
			if windowID == 1 then
				WindowControl(0, 0)  -- 驾驶座车窗
			elseif windowID == 2 then
				WindowControl(1, 1)  -- 副驾驶车窗
			elseif windowID == 3 then
				WindowControl(2, 2)  -- 后左车窗
			elseif windowID == 4 then
				WindowControl(3, 3)  -- 后右车窗
			end
		else
			TriggerEvent("chatMessage", "用法: ", {255, 0, 0}, "/window [车窗ID]")
		end
	end, false)

	-- 引擎盖命令
	TriggerEvent('chat:addSuggestion', '/hood', '打开/关闭引擎盖')

	RegisterCommand("hood", function(source, args, rawCommand)
		DoorControl(4)  -- 引擎盖
	end, false)

	-- 后备箱命令
	TriggerEvent('chat:addSuggestion', '/trunk', '打开/关闭后备箱')

	RegisterCommand("trunk", function(source, args, rawCommand)
		DoorControl(5)  -- 后备箱
	end, false)

	-- 前车窗命令
	TriggerEvent('chat:addSuggestion', '/windowfront', '升起/降下前车窗')

	RegisterCommand("windowfront", function(source, args, rawCommand)
		FrontWindowControl()
	end, false)

	-- 后车窗命令
	TriggerEvent('chat:addSuggestion', '/windowback', '升起/降下后车窗')

	RegisterCommand("windowback", function(source, args, rawCommand)
		BackWindowControl()
	end, false)

	-- 全部车窗命令
	TriggerEvent('chat:addSuggestion', '/windowall', '升起/降下所有车窗')

	RegisterCommand("windowall", function(source, args, rawCommand)
		AllWindowControl()
	end, false)
end

-- 强制关闭菜单命令
RegisterCommand("vehcontrolclose", function(source, args, rawCommand)
	closeVehControl()
end, false)

-- 显示帮助文本函数
function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end
