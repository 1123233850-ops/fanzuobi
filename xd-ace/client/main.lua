-- xd-ace 反作弊系统 - 客户端主文件

-- 全局变量
XDACE = {
    Player = {
        data = {},
        lastPosition = nil,
        lastVelocity = nil,
        lastHealth = nil,
        lastArmor = nil,
        lastAmmo = {},
        lastJump = 0,
        lastReload = 0,
        aimData = {
            lastTarget = nil,
            lastAngle = nil,
            targetSwitchCount = 0,
            consecutiveHeadshots = 0
        },
        movementData = {
            speed = 0,
            jumpHeight = 0,
            jumpDistance = 0,
            swimmingSpeed = 0
        },
        vehicleData = {
            lastVehicle = nil,
            lastSpeed = 0,
            lastHealth = nil
        }
    },
    Config = Config,
    Framework = nil,
    Detections = {},
    IsInitialized = false
}

-- 资源启动时的初始化
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- 框架将通过服务器端自动检测
    
    -- 加载检测模块
    LoadDetectionModules()
    
    -- 注册事件
    RegisterEvents()
    
    -- 启动主循环
    StartMainLoop()
    
    -- 初始化玩家数据
    InitializePlayerData()
    
    -- 日志记录
    Log('[XD-ACE] 客户端反作弊系统已成功启动', 'info')
    Log('[XD-ACE] 框架: ' .. XDACE.Framework:GetName(), 'info')
    Log('[XD-ACE] 检测模块数量: ' .. #XDACE.Detections, 'info')
    
    XDACE.IsInitialized = true
end)

-- 资源停止时的清理
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    XDACE.IsInitialized = false
    Log('[XD-ACE] 客户端反作弊系统已停止', 'info')
end)





-- 注册事件
function RegisterEvents()
    -- 玩家重生事件
    RegisterNetEvent('playerSpawned')
    AddEventHandler('playerSpawned', function()
        InitializePlayerData()
    end)
    
    -- 玩家死亡事件
    RegisterNetEvent('esx:onPlayerDeath')
    AddEventHandler('esx:onPlayerDeath', function()
        XDACE.Player.lastHealth = 0
        XDACE.Player.lastArmor = 0
    end)
    
    -- QB-Core 玩家死亡事件
    RegisterNetEvent('QBCore:Client:OnPlayerDeath')
    AddEventHandler('QBCore:Client:OnPlayerDeath', function()
        XDACE.Player.lastHealth = 0
        XDACE.Player.lastArmor = 0
    end)
    
    -- 打开管理员菜单事件
    RegisterNetEvent('xd-ace:openAdminMenu')
    AddEventHandler('xd-ace:openAdminMenu', function()
        OpenAdminMenu()
    end)
    
    -- 框架数据同步事件
    RegisterNetEvent('esx:setAccountMoney')
    AddEventHandler('esx:setAccountMoney', function(account)    
        SyncPlayerData()
    end)
    
    RegisterNetEvent('esx:addInventoryItem')
    AddEventHandler('esx:addInventoryItem', function(item, count)    
        SyncPlayerData()
    end)
    
    RegisterNetEvent('esx:removeInventoryItem')
    AddEventHandler('esx:removeInventoryItem', function(item, count)    
        SyncPlayerData()
    end)
    
    -- QB-Core 数据同步事件
    RegisterNetEvent('QBCore:Client:OnMoneyChange')
    AddEventHandler('QBCore:Client:OnMoneyChange', function(type, amount, reason)    
        SyncPlayerData()
    end)
    
    RegisterNetEvent('QBCore:Client:OnItemAdded')
    AddEventHandler('QBCore:Client:OnItemAdded', function(itemData, amount)    
        SyncPlayerData()
    end)
    
    RegisterNetEvent('QBCore:Client:OnItemRemoved')
    AddEventHandler('QBCore:Client:OnItemRemoved', function(itemData, amount)    
        SyncPlayerData()
    end)
end

-- 初始化玩家数据
function InitializePlayerData()
    local playerPed = PlayerPedId()
    
    XDACE.Player.lastPosition = GetEntityCoords(playerPed)
    XDACE.Player.lastVelocity = GetEntityVelocity(playerPed)
    XDACE.Player.lastHealth = GetEntityHealth(playerPed)
    XDACE.Player.lastArmor = GetPedArmour(playerPed)
    XDACE.Player.lastJump = GetGameTimer()
    XDACE.Player.lastReload = GetGameTimer()
    
    -- 初始化弹药数据
    local weapon = GetSelectedPedWeapon(playerPed)
    if weapon ~= nil and weapon ~= 0 then
        local ammoCount = GetAmmoInPedWeapon(playerPed, weapon)
        XDACE.Player.lastAmmo[weapon] = ammoCount
    end
    
    -- 同步玩家数据到服务器
    SyncPlayerData()
end

-- 同步玩家数据到服务器
function SyncPlayerData()
    local playerData = XDACE.Framework:GetPlayerData()
    if playerData then
        XDACE.Player.data = playerData
        TriggerServerEvent('xd-ace:syncData', playerData)
    end
end

-- 启动主循环
function StartMainLoop()
    -- 玩家数据更新循环
    CreateThread(function()
        while true do
            Wait(Config.AntiCheat.PlayerDataRefreshInterval)
            UpdatePlayerData()
        end
    end)
    
    -- 检测循环
    CreateThread(function()
        while true do
            Wait(Config.AntiCheat.scheduledDetection.interval * 1000)
            RunDetections()
        end
    end)
    
    -- 数据同步循环
    CreateThread(function()
        while true do
            Wait(5000)
            SyncPlayerData()
        end
    end)
    
    -- 瞄准数据更新循环
    CreateThread(function()
        while true do
            Wait(100)
            UpdateAimData()
        end
    end)
    
    -- 移动数据更新循环
    CreateThread(function()
        while true do
            Wait(200)
            UpdateMovementData()
        end
    end)
    
    -- 车辆数据更新循环
    CreateThread(function()
        while true do
            Wait(500)
            UpdateVehicleData()
        end
    end)
end

-- 更新玩家数据
function UpdatePlayerData()
    if not XDACE.IsInitialized then return end
    
    local playerPed = PlayerPedId()
    local currentPosition = GetEntityCoords(playerPed)
    local currentVelocity = GetEntityVelocity(playerPed)
    local currentHealth = GetEntityHealth(playerPed)
    local currentArmor = GetPedArmour(playerPed)
    
    -- 更新健康值和护甲值
    if currentHealth > Config.Detection.Godmode.Parameters.HealthThreshold then
        ReportViolation('godmode', '健康值超过阈值', 3, {
            health = currentHealth,
            maxAllowed = Config.Detection.Godmode.Parameters.HealthThreshold
        })
    end
    
    if currentArmor > Config.Detection.Godmode.Parameters.ArmorThreshold then
        ReportViolation('godmode', '护甲值超过阈值', 3, {
            armor = currentArmor,
            maxAllowed = Config.Detection.Godmode.Parameters.ArmorThreshold
        })
    end
    
    -- 更新弹药数据
    local weapon = GetSelectedPedWeapon(playerPed)
    if weapon ~= nil and weapon ~= 0 then
        local ammoCount = GetAmmoInPedWeapon(playerPed, weapon)
        
        if XDACE.Player.lastAmmo[weapon] then
            -- 检查无限弹药
            if ammoCount == XDACE.Player.lastAmmo[weapon] and IsPedShooting(playerPed) then
                ReportViolation('infiniteammo', '可能使用无限弹药', 3, {
                    weapon = weapon,
                    ammoCount = ammoCount,
                    lastAmmo = XDACE.Player.lastAmmo[weapon]
                })
            end
            
            -- 检查快速换弹
            if ammoCount > XDACE.Player.lastAmmo[weapon] then
                local reloadTime = GetGameTimer() - XDACE.Player.lastReload
                if reloadTime < Config.Detection.FastReload.Parameters.MinReloadTime then
                    ReportViolation('fastreload', '快速换弹检测', 2, {
                        weapon = weapon,
                        reloadTime = reloadTime,
                        minAllowed = Config.Detection.FastReload.Parameters.MinReloadTime
                    })
                end
                XDACE.Player.lastReload = GetGameTimer()
            end
        end
        
        XDACE.Player.lastAmmo[weapon] = ammoCount
    end
    
    -- 保存当前数据
    XDACE.Player.lastPosition = currentPosition
    XDACE.Player.lastVelocity = currentVelocity
    XDACE.Player.lastHealth = currentHealth
    XDACE.Player.lastArmor = currentArmor
end

-- 更新瞄准数据
function UpdateAimData()
    if not XDACE.IsInitialized then return end
    
    local playerPed = PlayerPedId()
    
    if IsPedAiming(playerPed) then
        local _, targetPed = GetEntityPlayerIsFreeAimingAt(playerPed)
        local currentAngle = GetGameplayCamRelativeHeading()
        
        -- 更新目标切换计数
        if targetPed ~= nil and targetPed ~= XDACE.Player.aimData.lastTarget then
            XDACE.Player.aimData.targetSwitchCount = XDACE.Player.aimData.targetSwitchCount + 1
            XDACE.Player.aimData.lastTarget = targetPed
            
            -- 检查目标切换速度
            if XDACE.Player.aimData.targetSwitchCount > Config.Detection.Aimbot.Parameters.MaxTargetSwitchSpeed then
                ReportViolation('aimbot', '目标切换速度过快', 3, {
                    switchCount = XDACE.Player.aimData.targetSwitchCount,
                    maxAllowed = Config.Detection.Aimbot.Parameters.MaxTargetSwitchSpeed
                })
            end
        end
        
        -- 更新角度变化
        if XDACE.Player.aimData.lastAngle then
            local angleDiff = math.abs(currentAngle - XDACE.Player.aimData.lastAngle)
            -- 这里可以添加更多瞄准辅助检测逻辑
        end
        
        XDACE.Player.aimData.lastAngle = currentAngle
    end
end

-- 更新移动数据
function UpdateMovementData()
    if not XDACE.IsInitialized then return end
    
    local playerPed = PlayerPedId()
    local currentPosition = GetEntityCoords(playerPed)
    local velocity = GetEntityVelocity(playerPed)
    
    -- 计算移动速度
    local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
    XDACE.Player.movementData.speed = speed
    
    -- 检查是否在地面上
    if IsPedOnGround(playerPed) then
        -- 检查行走速度
        if not IsPedInAnyVehicle(playerPed, false) and not IsPedSwimming(playerPed) then
            if speed > Config.Detection.Speedhack.Parameters.MaxOnFootSpeed * Config.Detection.Speedhack.Parameters.SpeedTolerance then
                ReportViolation('speedhack', '行走速度过快', 3, {
                    speed = speed,
                    maxAllowed = Config.Detection.Speedhack.Parameters.MaxOnFootSpeed
                })
            end
        end
        
        -- 检查游泳速度
        if IsPedSwimming(playerPed) then
            if speed > Config.Detection.Speedhack.Parameters.MaxSwimSpeed * Config.Detection.Speedhack.Parameters.SpeedTolerance then
                ReportViolation('speedhack', '游泳速度过快', 3, {
                    speed = speed,
                    maxAllowed = Config.Detection.Speedhack.Parameters.MaxSwimSpeed
                })
            end
        end
    else
        -- 检查跳跃
        if IsPedJumping(playerPed) then
            local currentTime = GetGameTimer()
            if currentTime - XDACE.Player.lastJump > 1000 then -- 防止重复检测
                XDACE.Player.lastJump = currentTime
                -- 这里可以添加跳跃高度检测逻辑
            end
        end
    end
end

-- 更新车辆数据
function UpdateVehicleData()
    if not XDACE.IsInitialized then return end
    
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local speed = GetEntitySpeed(vehicle) * 3.6 -- 转换为 km/h
        local health = GetVehicleEngineHealth(vehicle)
        
        -- 检查车辆速度
        if speed > Config.Detection.Speedhack.Parameters.MaxInVehicleSpeed * Config.Detection.Speedhack.Parameters.SpeedTolerance then
            ReportViolation('speedhack', '车辆速度过快', 3, {
                speed = speed,
                maxAllowed = Config.Detection.Speedhack.Parameters.MaxInVehicleSpeed
            })
        end
        
        -- 检查车辆健康值
        if health > Config.Detection.InvincibleVehicle.Parameters.MaxVehicleHealth then
            ReportViolation('invinciblevehicle', '车辆健康值异常', 3, {
                health = health,
                maxAllowed = Config.Detection.InvincibleVehicle.Parameters.MaxVehicleHealth
            })
        end
        
        XDACE.Player.vehicleData.lastVehicle = vehicle
        XDACE.Player.vehicleData.lastSpeed = speed
        XDACE.Player.vehicleData.lastHealth = health
    end
end

-- 运行所有检测模块
function RunDetections()
    for _, detection in ipairs(XDACE.Detections) do
        if detection.Enabled then
            local success, result = pcall(detection.Check)
            
            if success and result then
                ReportViolation(result.type, result.reason, result.severity, result.details)
            elseif not success then
                Log('[XD-ACE] 检测模块错误: ' .. detection.Name .. ' - ' .. result, 'error')
            end
        end
    end
end

-- 加载检测模块
function LoadDetectionModules()
    local detectionFiles = GetFilesInDirectory('client/detections')
    
    for _, file in ipairs(detectionFiles) do
        if string.ends(file, '.lua') then
            local module = require('./detections/' .. string.gsub(file, '.lua', ''))
            if module and module.Name and module.Enabled then
                table.insert(XDACE.Detections, module)
                Log('[XD-ACE] 加载客户端检测模块: ' .. module.Name, 'debug')
            end
        end
    end
end

-- 报告违规行为
function ReportViolation(type, reason, severity, details)
    if not XDACE.IsInitialized then return end
    
    local violationData = {
        type = type,
        reason = reason,
        severity = severity or 1,
        details = details or {}
    }
    
    -- 发送到服务器
    TriggerServerEvent('xd-ace:reportViolation', violationData)
    
    -- 客户端日志
    Log('[XD-ACE] 检测到违规: ' .. reason .. ' (类型: ' .. type .. ', 严重程度: ' .. severity .. ')', 'warning')
end

-- 打开管理员菜单
function OpenAdminMenu()
    -- 网页管理员菜单将通过NUI打开
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openMenu"
    })
end

-- 工具函数
function GetFilesInDirectory(directory)
    local files = {}  
    local file = io.popen('dir /b /a-d "' .. GetResourcePath(GetCurrentResourceName()) .. '/' .. directory .. '"')
    
    if file then
        for line in file:lines() do
            table.insert(files, line)
        end
        file:close()
    end
    
    return files
end

-- 字符串扩展
function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function string.ends(String, End)
    return End == '' or string.sub(String, -string.len(End)) == End
end

-- 日志记录函数
function Log(message, level)
    if not Config.Debug.Enabled then return end
    
    local levels = {
        info = 1,
        warning = 2,
        error = 3,
        debug = 4
    }
    
    local currentLevel = levels[Config.Debug.Level] or 1
    local messageLevel = levels[level] or 1
    
    if messageLevel <= currentLevel then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local logMessage = string.format("[%s] [%s] %s", timestamp, level:upper(), message)
        print(logMessage)
    end
end
