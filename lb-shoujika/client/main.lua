-- ============================================
-- LB手机运营商系统 - 客户端
-- ============================================

-- 加载ESX
ESX = exports['es_extended']:getSharedObject()

-- 等待玩家加载完成后发送通知
CreateThread(function()
    Wait(2000) -- 等待玩家完全加载
    TriggerServerEvent('lb-shoujika:clientLoaded')
    TriggerServerEvent('lb-shoujika:log', 'info', '客户端脚本已加载并初始化')
    print("^5[LB-SHOUJIKA] 客户端脚本已初始化^7")
end)

-- ============================================
-- 日志系统
-- ============================================
local LogLevels = {
    debug = 1,
    info = 2,
    warning = 3,
    error = 4
}

local function GetLogLevel()
    if not Config or not Config.Logging then return LogLevels.info end
    return LogLevels[Config.Logging.Level] or LogLevels.info
end

local function ShouldLog(level)
    if not Config or not Config.Logging then return true end -- 如果配置未加载，默认启用日志
    if not Config.Logging.Enabled then return false end
    return LogLevels[level] >= GetLogLevel()
end

local function FormatTimestamp()
    if not Config or not Config.Logging or not Config.Logging.ShowTimestamp then return "" end
    -- FiveM客户端环境不支持os.date，使用游戏时间作为替代
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    local seconds = GetClockSeconds()
    local timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    return string.format("[%s] ", timeStr)
end

function Log(level, message, ...)
    if not ShouldLog(level) then return end
    
    local formattedMessage = string.format(message, ...)
    local prefix = FormatTimestamp()
    local sourceTag = (Config and Config.Logging and Config.Logging.ShowSource) and "[客户端] " or ""
    local fullMessage = string.format("%s%s[LB-SHOUJIKA] %s: %s", prefix, sourceTag, level:upper(), formattedMessage)
    
    local f8Enabled = true
    if Config and Config.Logging and Config.Logging.F8 then
        f8Enabled = Config.Logging.F8.Enabled ~= false
    end
    
    if f8Enabled then
        print(fullMessage)
    end
    
    -- 同时输出到服务器控制台（通过服务器事件）
    TriggerServerEvent('lb-shoujika:log', level, formattedMessage)
end

-- 便捷函数
function LogDebug(message, ...)
    Log("debug", message, ...)
end

function LogInfo(message, ...)
    Log("info", message, ...)
end

function LogWarning(message, ...)
    Log("warning", message, ...)
end

function LogError(message, ...)
    Log("error", message, ...)
end

-- ============================================
-- 语言函数
-- ============================================
function _U(key, ...)
    local locale = Config.Locale or 'zh-cn'
    if Locales[locale] and Locales[locale][key] then
        return string.format(Locales[locale][key], ...)
    elseif Locales['zh-cn'] and Locales['zh-cn'][key] then
        return string.format(Locales['zh-cn'][key], ...)
    else
        return key
    end
end

-- ============================================
-- 通知函数
-- ============================================
local function Notify(title, message, type, duration)
    type = type or "info"
    duration = duration or Config.Notification.Duration
    
    if Config.Notification.System == "okokNotify" then
        exports['okokNotify']:Alert(title, message, duration, type)
    else
        ESX.ShowNotification(message)
    end
end

-- ============================================
-- 手机号更新事件处理
-- ============================================
RegisterNetEvent('lb-shoujika:phoneNumberUpdated')
AddEventHandler('lb-shoujika:phoneNumberUpdated', function(phoneNumber)
    LogInfo("收到手机号更新通知: %s", phoneNumber)
    
    if Config.Purchase.NotifyClient then
        Notify(_U('notify_phone_updated'), string.format(_U('notify_phone_installed') .. ": %s", phoneNumber), "success")
    end
    
    -- 通知lb-phone系统刷新手机号
    if exports['lb-phone'] then
        -- 尝试刷新手机系统
        Citizen.Wait(1000) -- 等待数据库更新完成
        -- 可以触发lb-phone的刷新事件（如果存在）
        TriggerEvent('lb-phone:refreshPhoneNumber')
        LogDebug("已触发lb-phone刷新事件")
    end
end)

local npcSpawned = false
local npcPed = nil
local npcBlip = nil
local isNearNPC = false

-- 已移动到文件开头

-- ============================================
-- NPC生成函数
-- ============================================
local function SpawnNPC()
    -- 检查是否已经生成过NPC，避免重复生成
    if npcSpawned and npcPed and DoesEntityExist(npcPed) then
        print("^3[LB-SHOUJIKA] NPC已经存在，跳过重复生成^7")
        return
    end
    
    print("^5[LB-SHOUJIKA] ===========================================^7")
    print("^5[LB-SHOUJIKA] NPC生成函数被调用^7")
    print("^5[LB-SHOUJIKA] ===========================================^7")
    TriggerServerEvent('lb-shoujika:log', 'info', 'NPC生成函数被调用')
    
    -- 检查配置
    if not Config then
        print("^1[LB-SHOUJIKA] 错误: Config未加载！^7")
        return
    end
    
    if not Config.NPC then
        print("^1[LB-SHOUJIKA] 错误: Config.NPC未找到！^7")
        return
    end
    
    print(string.format("^3[LB-SHOUJIKA] NPC配置检查: Enabled=%s^7", tostring(Config.NPC.Enabled)))
    
    if not Config.NPC.Enabled then 
        print("^3[LB-SHOUJIKA] NPC功能已禁用^7")
        LogInfo("NPC功能已禁用")
        return 
    end
    
    print("^2[LB-SHOUJIKA] 开始NPC生成流程...^7")
    LogInfo("开始NPC生成流程")
    
    -- 等待游戏完全加载
    print("^3[LB-SHOUJIKA] 等待游戏完全加载...^7")
    local waitCount = 0
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and waitCount < 50 do
        Wait(100)
        waitCount = waitCount + 1
    end
    
    if waitCount >= 50 then
        print("^3[LB-SHOUJIKA] 警告: 碰撞加载超时，继续执行...^7")
    end
    
    Wait(2000) -- 额外等待确保地图加载完成
    print("^2[LB-SHOUJIKA] 游戏加载完成，开始生成NPC^7")
    
    LogInfo("开始生成NPC，位置: x=%.2f, y=%.2f, z=%.2f, 朝向: %.2f", 
        Config.NPC.Coords.x, Config.NPC.Coords.y, Config.NPC.Coords.z, Config.NPC.Coords.w)
    
    print(string.format("^3[LB-SHOUJIKA] NPC坐标: x=%.2f, y=%.2f, z=%.2f, 朝向=%.2f^7", 
        Config.NPC.Coords.x, Config.NPC.Coords.y, Config.NPC.Coords.z, Config.NPC.Coords.w))
    
    -- 请求NPC模型
    print(string.format("^3[LB-SHOUJIKA] 请求NPC模型: %d^7", Config.NPC.Model))
    RequestModel(Config.NPC.Model)
    local timeout = 0
    while not HasModelLoaded(Config.NPC.Model) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(Config.NPC.Model) then
        print(string.format("^1[LB-SHOUJIKA] 错误: NPC模型加载超时: %d^7", Config.NPC.Model))
        LogError("NPC模型加载超时: %d", Config.NPC.Model)
        return
    end
    
    print("^2[LB-SHOUJIKA] NPC模型加载成功^7")
    
    -- 创建NPC
    print("^3[LB-SHOUJIKA] 正在创建NPC实体...^7")
    npcPed = CreatePed(4, Config.NPC.Model, Config.NPC.Coords.x, Config.NPC.Coords.y, Config.NPC.Coords.z - 1.0, Config.NPC.Coords.w, false, true)
    
    if not npcPed then
        print("^1[LB-SHOUJIKA] 错误: CreatePed返回nil^7")
        LogError("NPC创建失败！CreatePed返回nil")
        return
    end
    
    Wait(100) -- 等待实体创建完成
    
    if not DoesEntityExist(npcPed) then
        print(string.format("^1[LB-SHOUJIKA] 错误: NPC实体不存在，ID: %d^7", npcPed))
        LogError("NPC创建失败！实体不存在")
        return
    end
    
    print(string.format("^2[LB-SHOUJIKA] NPC实体创建成功，ID: %d^7", npcPed))
    
    SetEntityHeading(npcPed, Config.NPC.Coords.w)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetEntityCanBeDamaged(npcPed, false)
    SetPedCanRagdollFromPlayerImpact(npcPed, false)
    SetPedFleeAttributes(npcPed, 0, false)
    SetPedCombatAttributes(npcPed, 46, true)
    
    -- 启动NPC动作
    TaskStartScenarioInPlace(npcPed, Config.NPC.Scenario, 0, true)
    
    npcSpawned = true
    print(string.format("^2[LB-SHOUJIKA] NPC生成成功，实体ID: %d^7", npcPed))
    LogInfo("NPC生成成功，实体ID: %d", npcPed)
    
    -- 创建Blip（地图标记）
    if Config.NPC.Blip then
        print(string.format("^3[LB-SHOUJIKA] Blip配置检查: Enabled=%s^7", tostring(Config.NPC.Blip.Enabled)))
    else
        print("^1[LB-SHOUJIKA] 错误: Config.NPC.Blip未找到！^7")
    end
    
    if Config.NPC.Blip and Config.NPC.Blip.Enabled then
        print("^3[LB-SHOUJIKA] 开始创建地图标记...^7")
        Wait(500) -- 等待一下再创建Blip
        
        npcBlip = AddBlipForCoord(Config.NPC.Coords.x, Config.NPC.Coords.y, Config.NPC.Coords.z)
        print(string.format("^3[LB-SHOUJIKA] AddBlipForCoord返回: %s^7", tostring(npcBlip)))
        
        if npcBlip then
            print(string.format("^3[LB-SHOUJIKA] 检查Blip是否存在: %s^7", tostring(DoesBlipExist(npcBlip))))
        end
        
        if npcBlip and DoesBlipExist(npcBlip) then
            print("^2[LB-SHOUJIKA] Blip创建成功，开始设置属性...^7")
            SetBlipSprite(npcBlip, Config.NPC.Blip.Sprite)
            SetBlipColour(npcBlip, Config.NPC.Blip.Color)
            SetBlipScale(npcBlip, Config.NPC.Blip.Scale)
            SetBlipAsShortRange(npcBlip, false) -- 改为全局显示，不需要靠近就能看到
            SetBlipCategory(npcBlip, 10) -- 设置为服务类别
            SetBlipDisplay(npcBlip, 4) -- 始终显示
            SetBlipAsMissionCreatorBlip(npcBlip, true) -- 设置为任务标记
            
            -- 设置标记名称
            local blipName = _U('npc_blip_name') or Config.NPC.Blip.Name or "手机运营商"
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(blipName)
            EndTextCommandSetBlipName(npcBlip)
            
            print(string.format("^2[LB-SHOUJIKA] 地图标记创建成功: %s (Blip ID: %d)^7", blipName, npcBlip))
            LogInfo("地图标记已创建: %s (Blip ID: %d, 图标ID: %d, 颜色: %d, 坐标: %.2f, %.2f, %.2f)", 
                blipName, npcBlip, Config.NPC.Blip.Sprite, Config.NPC.Blip.Color, 
                Config.NPC.Coords.x, Config.NPC.Coords.y, Config.NPC.Coords.z)
        else
            print(string.format("^1[LB-SHOUJIKA] 错误: 创建地图标记失败！Blip ID: %s, 存在: %s^7", 
                tostring(npcBlip), tostring(npcBlip and DoesBlipExist(npcBlip))))
            LogError("创建地图标记失败！Blip ID: %s", tostring(npcBlip))
        end
    else
        print("^3[LB-SHOUJIKA] 地图标记功能已禁用^7")
        LogInfo("地图标记功能已禁用")
    end
    
    -- 添加ox_target交互（等待NPC完全创建）
    CreateThread(function()
        Wait(1000) -- 等待NPC完全创建
        
        local oxTarget = exports.ox_target or exports['ox_target']
        if oxTarget and npcPed and DoesEntityExist(npcPed) then
            local success, err = pcall(function()
                oxTarget:addLocalEntity(npcPed, {
                    {
                        name = 'lb-shoujika-operator',
                        icon = 'fa-solid fa-mobile-screen',
                        label = _U('npc_interact') or '打开手机运营商',
                        onSelect = function()
                            LogInfo("玩家通过ox_target打开运营商菜单")
                            OpenOperatorMenu()
                        end
                    }
                })
            end)
            
            if success then
                LogInfo("已为NPC添加ox_target交互")
                print("^2[LB-SHOUJIKA] ox_target交互已添加^7")
            else
                LogError("添加ox_target交互失败: %s", tostring(err))
                print("^1[LB-SHOUJIKA] ox_target交互添加失败: " .. tostring(err) .. "^7")
            end
        else
            if not oxTarget then
                LogWarning("ox_target未找到，无法添加交互点")
                print("^3[LB-SHOUJIKA] 警告: ox_target未找到，请确保ox_target资源已启动^7")
            end
        end
    end)
    
    print("^2[LB-SHOUJIKA] NPC生成流程完成^7")
end

-- ============================================
-- 资源启动日志
-- ============================================
CreateThread(function()
    -- 立即输出启动信息（不依赖配置）
    print("============================================")
    print("[LB-SHOUJIKA] 客户端脚本正在启动...")
    
    Wait(3000) -- 等待资源完全加载，确保Config已加载
    
    -- 检查配置是否加载
    if not Config then
        print("[LB-SHOUJIKA] 警告: Config未加载，使用默认日志设置")
        -- 使用默认设置
        Config = {}
        Config.Logging = {
            Enabled = true,
            Level = "info",
            ShowTimestamp = true,
            ShowSource = true,
            Console = { Enabled = true, Colors = true },
            F8 = { Enabled = true }
        }
    end
    
    if not Config.Logging then
        print("[LB-SHOUJIKA] 警告: Config.Logging未找到，使用默认日志设置")
        Config.Logging = {
            Enabled = true,
            Level = "info",
            ShowTimestamp = true,
            ShowSource = true,
            Console = { Enabled = true, Colors = true },
            F8 = { Enabled = true }
        }
    end
    
    -- 检查ESX是否加载
    if not ESX then
        print("[LB-SHOUJIKA] 警告: ESX未加载！请确保es_extended资源已启动")
    end
    
    -- 输出详细启动信息
    if Config.Logging.Enabled then
        LogInfo("============================================")
        LogInfo("LB手机运营商系统客户端已启动")
        LogInfo("ESX框架: %s", ESX and "已加载" or "未加载")
        LogInfo("日志系统: 已启用")
        LogInfo("日志级别: %s", Config.Logging.Level or "info")
        LogInfo("调试模式: %s", (Config.Debug and "开启" or "关闭"))
        LogInfo("F8控制台: %s", ((Config.Logging.F8 and Config.Logging.F8.Enabled) and "开启" or "关闭"))
        LogInfo("============================================")
        
        -- 测试日志输出
        LogInfo("测试日志: 这是一条测试信息")
        LogWarning("测试日志: 这是一条测试警告")
        
        -- 资源启动完成后，调用NPC生成
        Wait(2000) -- 再等待2秒确保一切就绪
        print("^5[LB-SHOUJIKA] 准备在资源启动后生成NPC^7")
        TriggerServerEvent('lb-shoujika:log', 'info', '准备在资源启动后生成NPC')
        if Config and Config.NPC then
            TriggerServerEvent('lb-shoujika:log', 'info', 'Config和Config.NPC已找到，开始生成NPC')
            SpawnNPC()
        else
            print("^1[LB-SHOUJIKA] 错误: Config或Config.NPC未找到，无法生成NPC^7")
            TriggerServerEvent('lb-shoujika:log', 'error', 'Config或Config.NPC未找到，无法生成NPC')
        end
    else
        print("[LB-SHOUJIKA] 警告: 日志系统未启用，请在config.lua中设置Config.Logging.Enabled = true")
        -- 即使日志未启用，也尝试生成NPC
        Wait(5000)
        if Config and Config.NPC then
            SpawnNPC()
        end
    end
end)

-- ============================================
-- 资源停止时清理
-- ============================================
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- 清理ox_target
        local oxTarget = exports.ox_target or exports['ox_target']
        if npcPed and DoesEntityExist(npcPed) and oxTarget then
            pcall(function()
                oxTarget:removeLocalEntity(npcPed, 'lb-shoujika-operator')
            end)
        end
        
        -- 清理NPC
        if npcPed and DoesEntityExist(npcPed) then
            DeleteEntity(npcPed)
            LogInfo("NPC已清理")
        end
        
        -- 清理地图标记
        if npcBlip and DoesBlipExist(npcBlip) then
            RemoveBlip(npcBlip)
            LogInfo("地图标记已清理")
        end
    end
end)

-- ============================================
-- 打开运营商菜单
-- ============================================
function OpenOperatorMenu()
    LogInfo("打开运营商菜单")
    
    -- 确保ESX已加载
    if not ESX then
        LogError("ESX未加载，无法打开菜单")
        print("^1[LB-SHOUJIKA] 错误: ESX未加载，无法打开菜单^7")
        return
    end
    
    ESX.TriggerServerCallback('lb-shoujika:getMyNumbers', function(myNumbers)
        if not myNumbers then
            LogError("获取手机号列表失败")
            myNumbers = {}
        end
        
        LogDebug("获取到 %d 个手机号", #myNumbers)
        
        local elements = {}
        
        -- 我的手机号
        table.insert(elements, {
            label = _U('menu_my_numbers'),
            value = "my_numbers"
        })
        
        -- 购买新号码
        table.insert(elements, {
            label = _U('menu_purchase'),
            value = "purchase"
        })
        
        -- 充值话费
        if #myNumbers > 0 then
            table.insert(elements, {
                label = _U('menu_recharge'),
                value = "recharge"
            })
        end
        
        -- 检查ESX.UI.Menu是否存在
        if not ESX.UI or not ESX.UI.Menu then
            LogError("ESX.UI.Menu未找到，无法打开菜单")
            if exports.ox_lib then
                exports.ox_lib:notify({
                    title = "错误",
                    description = "菜单系统未加载",
                    type = "error"
                })
            else
                print("^1[LB-SHOUJIKA] 错误: ESX.UI.Menu未找到^7")
            end
            return
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'operator_main', {
            title = _U('menu_operator'),
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            if not data or not data.current then
                LogError("菜单数据错误")
                return
            end
            
            LogDebug("菜单选项: %s", data.current.value)
            if data.current.value == 'my_numbers' then
                OpenMyNumbersMenu(myNumbers)
            elseif data.current.value == 'purchase' then
                OpenPurchaseMenu()
            elseif data.current.value == 'recharge' then
                OpenRechargeMenu(myNumbers)
            end
        end, function(data, menu)
            if menu then
                menu.close()
            end
        end)
    end, function()
        LogError("获取手机号列表的服务器回调失败")
        if exports.ox_lib then
            exports.ox_lib:notify({
                title = "错误",
                description = "无法连接到服务器",
                type = "error"
            })
        end
    end)
end

-- ============================================
-- 我的手机号菜单
-- ============================================
function OpenMyNumbersMenu(numbers)
    if #numbers == 0 then
        Notify(_U('info'), _U('notify_no_numbers'), "info")
        return
    end
    
    local elements = {}
    for _, number in ipairs(numbers) do
        local statusText = ""
        if number.status == 'active' then
            statusText = _U('status_active')
        elseif number.status == 'inactive' then
            statusText = _U('status_inactive')
        elseif number.status == 'suspended' then
            statusText = _U('status_suspended')
        elseif number.status == 'expired' then
            statusText = _U('status_expired')
        end
        
        table.insert(elements, {
            label = string.format("%s | %s | 余额: $%d", number.phone_number, statusText, number.balance),
            value = number.phone_number,
            number = number
        })
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'my_numbers', {
        title = _U('menu_my_numbers_title'),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local numberData = data.current.number
        OpenNumberDetailMenu(numberData)
    end, function(data, menu)
        menu.close()
    end)
end

-- ============================================
-- 手机号详情菜单
-- ============================================
function OpenNumberDetailMenu(numberData)
    local elements = {}
    
    -- 激活/停用
    if numberData.status == 'inactive' then
        table.insert(elements, {
            label = _U('action_activate'),
            value = "activate"
        })
    end
    
    -- 查看余额
    table.insert(elements, {
        label = string.format(_U('action_view_balance') .. ": $%d", numberData.balance),
        value = "balance"
    })
    
    -- 充值记录
    table.insert(elements, {
        label = _U('action_view_recharge_history'),
        value = "recharge_history"
    })
    
    -- 消费记录
    table.insert(elements, {
        label = _U('action_view_charge_history'),
        value = "charge_history"
    })
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'number_detail', {
        title = string.format(_U('menu_number_detail') .. ": %s", numberData.phone_number),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'activate' then
            ESX.TriggerServerCallback('lb-shoujika:activateNumber', function(success, message)
                if success then
                    LogInfo("激活手机号成功: %s", numberData.phone_number)
                    Notify(_U('notify_activate_success'), _U('activate_success'), "success")
                    menu.close()
                else
                    LogWarning("激活手机号失败: %s, 原因=%s", numberData.phone_number, message or _U('activate_failed'))
                    Notify(_U('notify_activate_failed'), message or _U('activate_failed'), "error")
                end
            end, numberData.phone_number)
        elseif data.current.value == 'recharge_history' then
            ShowRechargeHistory(numberData.phone_number)
        elseif data.current.value == 'charge_history' then
            ShowChargeHistory(numberData.phone_number)
        end
    end, function(data, menu)
        menu.close()
    end)
end

-- ============================================
-- 购买菜单
-- ============================================
function OpenPurchaseMenu()
    ESX.TriggerServerCallback('lb-shoujika:getPackages', function(packages)
        if #packages == 0 then
            Notify(_U('info'), _U('notify_no_packages'), "info")
            return
        end
        
        local elements = {}
        for _, package in ipairs(packages) do
            table.insert(elements, {
                label = string.format("%s - $%d | 初始余额: $%d | 周租: $%d", 
                    package.name, package.price, package.initial_balance, package.weekly_fee or 0),
                value = package.id,
                package = package
            })
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'purchase', {
            title = _U('menu_purchase_title'),
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            local package = data.current.package
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'purchase_confirm', {
                title = _U('purchase_confirm', package.name)
            }, function(data2, menu2)
                menu2.close()
                
        ESX.TriggerServerCallback('lb-shoujika:purchaseNumber', function(success, message)
            if success then
                LogInfo("购买手机号成功: %s", message)
                Notify(_U('notify_purchase_success'), string.format(_U('purchase_phone_number'), message), "success")
                menu.close()
            else
                LogWarning("购买手机号失败: %s", message or _U('purchase_failed'))
                Notify(_U('notify_purchase_failed'), message or _U('purchase_failed'), "error")
            end
        end, package.id)
            end, function(data2, menu2)
                menu2.close()
            end)
        end, function(data, menu)
            menu.close()
        end)
    end)
end

-- ============================================
-- 充值菜单
-- ============================================
function OpenRechargeMenu(numbers)
    if #numbers == 0 then
        Notify(_U('info'), _U('notify_no_numbers'), "info")
        return
    end
    
    local elements = {}
    for _, number in ipairs(numbers) do
        table.insert(elements, {
            label = string.format("%s | 余额: $%d", number.phone_number, number.balance),
            value = number.phone_number,
            number = number
        })
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'recharge_select', {
        title = "选择要充值的手机号",
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local phoneNumber = data.current.value
        
        -- 选择充值方式
        local methodElements = {}
        if Config.Recharge.Methods.cash then
            table.insert(methodElements, { label = _U('recharge_method_cash'), value = "cash" })
        end
        if Config.Recharge.Methods.bank then
            table.insert(methodElements, { label = _U('recharge_method_bank'), value = "bank" })
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'recharge_method', {
            title = _U('menu_recharge_method'),
            align = 'top-left',
            elements = methodElements
        }, function(data2, menu2)
            local method = data2.current.value
            
            -- 输入充值金额
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'recharge_amount', {
                title = _U('recharge_amount_range', Config.Recharge.MinAmount, Config.Recharge.MaxAmount)
            }, function(data3, menu3)
                local amount = tonumber(data3.value)
                
                if not amount or amount < Config.Recharge.MinAmount or amount > Config.Recharge.MaxAmount then
                    Notify(_U('error'), _U('recharge_amount_invalid', Config.Recharge.MinAmount, Config.Recharge.MaxAmount), "error")
                    return
                end
                
                menu3.close()
                menu2.close()
                menu.close()
                
                ESX.TriggerServerCallback('lb-shoujika:rechargeBalance', function(success, message)
                    if success then
                        LogInfo("充值成功: 手机号=%s, 金额=$%d, 余额=$%d", phoneNumber, amount, message)
                        Notify(_U('notify_recharge_success'), string.format(_U('recharge_current_balance'), message), "success")
                    else
                        LogWarning("充值失败: 手机号=%s, 金额=$%d, 原因=%s", phoneNumber, amount, message or _U('recharge_failed'))
                        Notify(_U('notify_recharge_failed'), message or _U('recharge_failed'), "error")
                    end
                end, phoneNumber, amount, method)
            end, function(data3, menu3)
                menu3.close()
            end)
        end, function(data2, menu2)
            menu2.close()
        end)
    end, function(data, menu)
        menu.close()
    end)
end

-- ============================================
-- 显示充值记录
-- ============================================
function ShowRechargeHistory(phoneNumber)
    ESX.TriggerServerCallback('lb-shoujika:getRechargeHistory', function(history)
        if #history == 0 then
            Notify(_U('info'), _U('notify_no_recharge_history'), "info")
            return
        end
        
        local elements = {}
        for _, record in ipairs(history) do
            -- 服务器端应该返回格式化的日期字符串，如果没有则显示原始值
            local date = record.created_at or "未知时间"
            if type(date) == "number" then
                -- 如果是时间戳，简单显示
                date = "时间戳:" .. date
            end
            table.insert(elements, {
                label = string.format("%s | +$%d | %s", date, record.amount, record.method or "未知")
            })
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'recharge_history', {
            title = _U('menu_recharge_history'),
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            menu.close()
        end, function(data, menu)
            menu.close()
        end)
    end, phoneNumber)
end

-- ============================================
-- 显示消费记录
-- ============================================
function ShowChargeHistory(phoneNumber)
    ESX.TriggerServerCallback('lb-shoujika:getChargeHistory', function(history)
        if #history == 0 then
            Notify(_U('info'), _U('notify_no_charge_history'), "info")
            return
        end
        
        local elements = {}
        for _, record in ipairs(history) do
            -- 服务器端应该返回格式化的日期字符串，如果没有则显示原始值
            local date = record.created_at or "未知时间"
            if type(date) == "number" then
                -- 如果是时间戳，简单显示
                date = "时间戳:" .. date
            end
            local typeText = ""
            if record.type == 'call' then
                typeText = _U('charge_type_call')
            elseif record.type == 'sms' then
                typeText = _U('charge_type_sms')
            elseif record.type == 'data' then
                typeText = _U('charge_type_data')
            elseif record.type == 'weekly_fee' then
                typeText = _U('charge_type_weekly_fee')
            else
                typeText = _U('charge_type_other')
            end
            
            table.insert(elements, {
                label = string.format("%s | %s | -$%d", date, typeText, record.amount)
            })
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'charge_history', {
            title = _U('menu_charge_history'),
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            menu.close()
        end, function(data, menu)
            menu.close()
        end)
    end, phoneNumber)
end

