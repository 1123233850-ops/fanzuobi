-- xd-ace 反作弊系统 - 服务器主文件

-- 全局变量
XDACE = {
    Players = {},
    Detections = {},
    Framework = nil,
    Config = Config,
    Database = nil
}

-- 资源启动时的初始化
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- 加载框架
    XDACE.Framework = {}  -- 框架检测将在framework/detector.lua中处理
    
    -- 加载数据库模块
    XDACE.Database = {}  -- 数据库将在database/init.lua中初始化
    
    -- 加载检测模块
    LoadDetectionModules()
    
    -- 注册事件
    RegisterEvents()
    
    -- 注册命令
    RegisterCommands()
    
    -- 启动主循环
    StartMainLoop()
    
    -- 日志记录
    Log('[XD-ACE] 反作弊系统已成功启动', 'info')
    Log('[XD-ACE] 检测模块数量: ' .. #XDACE.Detections, 'info')
end)

-- 加载检测模块
function LoadDetectionModules()
    local detectionFiles = GetFilesInDirectory('server/detections')
    
    for _, file in ipairs(detectionFiles) do
        if string.ends(file, '.lua') then
            local module = require('./detections/' .. string.gsub(file, '.lua', ''))
            if module and module.Name and module.Enabled then
                table.insert(XDACE.Detections, module)
                Log('[XD-ACE] 加载检测模块: ' .. module.Name, 'debug')
            end
        end
    end
end



-- 注册事件
function RegisterEvents()
    -- 玩家连接事件
    AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
        local playerId = source
        local identifiers = GetPlayerIdentifiers(playerId)
        
        -- 检查封禁状态
        XDACE.Database:CheckBan(identifiers, function(isBanned, banInfo)
            if isBanned then
                setKickReason(string.format(Config.Punishments.Ban.Message, banInfo.reason, banInfo.id, banInfo.admin))
                CancelEvent()
            else
                -- 初始化玩家数据
                XDACE.Players[playerId] = {
                    id = playerId,
                    name = playerName,
                    identifiers = identifiers,
                    violations = {},
                    lastDetection = 0,
                    data = {}
                }
                
                -- 获取玩家框架数据
                XDACE.Framework:GetPlayerData(playerId, function(playerData)
                    XDACE.Players[playerId].data = playerData
                end)
            end
        end)
    end)
    
    -- 玩家断开连接事件
    AddEventHandler('playerDropped', function(reason)
        local playerId = source
        XDACE.Players[playerId] = nil
    end)
    
    -- 客户端违规报告事件
    RegisterNetEvent('xd-ace:reportViolation')
    AddEventHandler('xd-ace:reportViolation', function(violationData)
        local playerId = source
        HandleViolation(playerId, violationData)
    end)
    
    -- 客户端数据同步事件
    RegisterNetEvent('xd-ace:syncData')
    AddEventHandler('xd-ace:syncData', function(data)
        local playerId = source
        if XDACE.Players[playerId] then
            XDACE.Players[playerId].data = data
        end
    end)
end

-- 注册命令
function RegisterCommands()
    -- 管理员主命令
    RegisterCommand('xdace', function(source, args, rawCommand)
        if IsAdmin(source) then
            -- 显示管理员菜单
            TriggerClientEvent('xd-ace:openAdminMenu', source)
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'[XD-ACE]', '你没有权限使用此命令!'}
            })
        end
    end)
    
    -- 封禁玩家命令
    RegisterCommand('xdaceban', function(source, args, rawCommand)
        if IsAdmin(source, 3) then
            local targetId = tonumber(args[1])
            local reason = table.concat(args, ' ', 2) or '未指定理由'
            
            if targetId and GetPlayerName(targetId) then
                BanPlayer(targetId, reason, GetPlayerName(source))
            end
        end
    end)
    
    -- 警告玩家命令
    RegisterCommand('xdacewarn', function(source, args, rawCommand)
        if IsAdmin(source, 2) then
            local targetId = tonumber(args[1])
            local reason = table.concat(args, ' ', 2) or '未指定理由'
            
            if targetId and GetPlayerName(targetId) then
                WarnPlayer(targetId, reason, GetPlayerName(source))
            end
        end
    end)
    
    -- 踢玩家命令
    RegisterCommand('xdacekick', function(source, args, rawCommand)
        if IsAdmin(source, 2) then
            local targetId = tonumber(args[1])
            local reason = table.concat(args, ' ', 2) or '未指定理由'
            
            if targetId and GetPlayerName(targetId) then
                KickPlayer(targetId, reason)
            end
        end
    end)
    
    -- 清除违规记录命令
    RegisterCommand('xdaceclear', function(source, args, rawCommand)
        if IsAdmin(source, 3) then
            local targetId = tonumber(args[1])
            
            if targetId and GetPlayerName(targetId) then
                ClearViolations(targetId)
            end
        end
    end)
    
    -- 解封玩家命令
    RegisterCommand('xdaceunban', function(source, args, rawCommand)
        if IsAdmin(source, 3) then
            local banId = tonumber(args[1])
            local adminName = GetPlayerName(source) or '控制台'
            local adminLicense = GetPlayerIdentifiers(source)[1] or 'console'
            
            if banId then
                UnbanPlayer(banId, adminLicense, adminName)
                TriggerClientEvent('chat:addMessage', source, {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {'[XD-ACE]', '成功解封封禁ID: ' .. banId}
                })
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'[XD-ACE]', '用法: /xdaceunban <封禁ID>'}
                })
            end
        end
    end)
end



-- 运行所有检测模块
function RunDetections(playerId)
    for _, detection in ipairs(XDACE.Detections) do
        if detection.Enabled then
            local success, result = pcall(detection.Check, playerId)
            
            if success and result then
                HandleViolation(playerId, result)
            elseif not success then
                Log('[XD-ACE] 检测模块错误: ' .. detection.Name .. ' - ' .. result, 'error')
            end
        end
    end
end

-- 处理违规行为
function HandleViolation(playerId, violationData)
    local player = XDACE.Players[playerId]
    if not player then return end
    
    -- 记录违规
    table.insert(player.violations, {
        type = violationData.type,
        reason = violationData.reason,
        severity = violationData.severity or 1,
        timestamp = os.time(),
        details = violationData.details or {}
    })
    
    -- 数据库记录
    XDACE.Database:LogViolation(playerId, violationData)
    
    -- 管理员通知
    if Config.AntiCheat.AdminAlerts.Enabled then
        NotifyAdmins(playerId, violationData)
    end
    
    -- 根据违规次数执行处罚
    local violationCount = #player.violations
    
    if violationCount >= Config.AntiCheat.ViolationActions.BanThreshold then
        BanPlayer(playerId, violationData.reason, '自动封禁')
    elseif violationCount >= Config.AntiCheat.ViolationActions.KickThreshold then
        KickPlayer(playerId, violationData.reason)
    elseif violationCount >= Config.AntiCheat.ViolationActions.WarnThreshold then
        WarnPlayer(playerId, violationData.reason, '自动警告')
    end
    
    -- 日志记录
    Log('[XD-ACE] 玩家: ' .. GetPlayerName(playerId) .. ' 违规: ' .. violationData.reason .. ' (次数: ' .. violationCount .. ')', 'warning')
end

-- 警告玩家
function WarnPlayer(playerId, reason, admin)
    local playerName = GetPlayerName(playerId)
    
    -- 发送警告消息
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 255, 0},
        multiline = true,
        args = {'[XD-ACE]', string.format(Config.Punishments.Warning.Message, reason)}
    })
    
    -- 日志记录
    Log('[XD-ACE] 警告玩家: ' .. playerName .. ' 理由: ' .. reason .. ' 管理员: ' .. admin, 'info')
    
    -- 数据库记录
    XDACE.Database:LogAction(playerId, {
        type = 'warn',
        reason = reason,
        admin = admin
    })
end

-- 踢玩家
function KickPlayer(playerId, reason)
    local playerName = GetPlayerName(playerId)
    
    -- 踢出玩家
    DropPlayer(playerId, string.format(Config.Punishments.Kick.Message, reason))
    
    -- 日志记录
    Log('[XD-ACE] 踢玩家: ' .. playerName .. ' 理由: ' .. reason, 'info')
    
    -- 数据库记录
    XDACE.Database:LogAction(playerId, {
        type = 'kick',
        reason = reason,
        admin = '自动踢人'
    })
end

-- 封禁玩家
function BanPlayer(playerId, reason, admin)
    local playerName = GetPlayerName(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    
    -- 生成违规ID
    local violationId = GenerateViolationId()
    
    -- 封禁理由
    local banReason = Config.Punishments.Ban.BanReasons[reason] or reason
    
    -- 数据库记录
    XDACE.Database:AddBan(playerId, {
        reason = banReason,
        duration = Config.Punishments.Ban.BanType == 'permanent' and 0 or Config.Punishments.Ban.DefaultBanDuration,
        admin = admin,
        violationId = violationId
    })
    
    -- 踢出玩家
    DropPlayer(playerId, string.format(Config.Punishments.Ban.Message, banReason, violationId, admin))
    
    -- 广播通知
    if Config.Punishments.Ban.Broadcast then
        TriggerClientEvent('chat:addMessage', -1, {
            color = {255, 0, 0},
            multiline = true,
            args = {'[XD-ACE]', '玩家 ' .. playerName .. ' 因违反服务器规则被永久封禁!'}
        })
    end
    
    -- 日志记录
    Log('[XD-ACE] 封禁玩家: ' .. playerName .. ' 理由: ' .. banReason .. ' 管理员: ' .. admin, 'info')
    
    -- 数据库记录
    XDACE.Database:LogAction(playerId, {
        type = 'ban',
        reason = banReason,
        admin = admin
    })
end

-- 清除玩家违规记录
function ClearViolations(playerId)
    if XDACE.Players[playerId] then
        XDACE.Players[playerId].violations = {}
        Log('[XD-ACE] 清除玩家违规记录: ' .. GetPlayerName(playerId), 'info')
    end
end

-- 解封玩家
function UnbanPlayer(banId, adminLicense, adminName)
    -- 调用数据库解封函数
    Database.UnbanPlayer(banId, adminLicense, adminName)
    Log('[XD-ACE] 解封玩家: 封禁ID ' .. banId .. ' 由 ' .. adminName .. ' 解封', 'info')
end

-- 管理员通知
function NotifyAdmins(playerId, violationData)
    local playerName = GetPlayerName(playerId)
    local message = string.format('[XD-ACE] 玩家 %s 违规: %s (严重程度: %d)', playerName, violationData.reason, violationData.severity or 1)
    
    -- 聊天通知
    if Config.AntiCheat.AdminAlerts.NotifyType == 'chat' or Config.AntiCheat.AdminAlerts.NotifyType == 'both' then
        for adminId, adminData in pairs(XDACE.Players) do
            if IsAdmin(adminId) then
                TriggerClientEvent('chat:addMessage', adminId, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'[XD-ACE]', message}
                })
            end
        end
    end
    
    -- Discord 通知
    if Config.AntiCheat.AdminAlerts.NotifyType == 'discord' or Config.AntiCheat.AdminAlerts.NotifyType == 'both' then
        SendDiscordWebhook(message, violationData)
    end
end

-- 检查资源完整性
function CheckResourceIntegrity()
    -- 这里可以添加资源完整性检查逻辑
end

-- 发送 Discord Webhook
function SendDiscordWebhook(message, violationData)
    -- 这里可以添加 Discord Webhook 发送逻辑
end

-- 生成违规ID
function GenerateViolationId()
    return string.upper(string.sub(tostring(os.time()) .. tostring(math.random(1000, 9999)), 1, 10))
end

-- 检查是否为管理员
function IsAdmin(playerId, level)
    if playerId == 0 then return true end -- 控制台
    
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, license in ipairs(identifiers) do
        if string.starts(license, 'license:') then
            for _, adminLicense in ipairs(Config.Admin.Licenses) do
                if license == adminLicense then
                    return true
                end
            end
        end
    end
    
    return false
end

-- 工具函数
function GetFilesInDirectory(directory)
    local files = {}
    local path = GetResourcePath(GetCurrentResourceName()) .. '/' .. directory
    
    local file = io.popen('dir /b /a-d "' .. path .. '"')
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

-- 主检测循环
function StartMainLoop()
    CreateThread(function()
        while true do
            Wait(Config.AntiCheat.scheduledDetection.interval * 1000)
            
            for playerId, playerData in pairs(XDACE.Players) do
                -- 检查玩家是否在线
                if GetPlayerPing(playerId) > 0 then
                    -- 运行检测
                    RunDetections(playerId)
                end
            end
        end
    end)
end

-- 导出函数
function GetPlayerData(playerId)
    return XDACE.Players[playerId] or nil
end

exports('GetPlayerData', GetPlayerData)

function GetFramework()
    return XDACE.Framework
end

exports('GetFramework', GetFramework)

function GetConfig()
    return XDACE.Config
end

exports('GetConfig', GetConfig)

function ExportHandleViolation(playerId, violationData)
    HandleViolation(playerId, violationData)
end

exports('HandleViolation', ExportHandleViolation)
