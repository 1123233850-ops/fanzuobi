-- ============================================
-- LB手机运营商系统 - 服务器端
-- ============================================

ESX = exports['es_extended']:getSharedObject()

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
    local time = os.date("%Y-%m-%d %H:%M:%S")
    return string.format("[%s] ", time)
end

local function GetColorCode(level)
    if not Config or not Config.Logging or not Config.Logging.Console or not Config.Logging.Console.Colors then return "" end
    local colors = {
        debug = "^7",    -- 白色
        info = "^2",     -- 绿色
        warning = "^3",  -- 黄色
        error = "^1"     -- 红色
    }
    return colors[level] or ""
end

function Log(level, message, ...)
    if not ShouldLog(level) then return end
    
    local formattedMessage = string.format(message, ...)
    local prefix = FormatTimestamp()
    local sourceTag = (Config and Config.Logging and Config.Logging.ShowSource) and "[服务器] " or ""
    local colorCode = GetColorCode(level)
    local resetCode = (Config and Config.Logging and Config.Logging.Console and Config.Logging.Console.Colors) and "^7" or ""
    local fullMessage = string.format("%s%s%s[LB-SHOUJIKA] %s: %s%s", 
        colorCode, prefix, sourceTag, level:upper(), formattedMessage, resetCode)
    
    local consoleEnabled = true
    if Config and Config.Logging and Config.Logging.Console then
        consoleEnabled = Config.Logging.Console.Enabled ~= false
    end
    
    if consoleEnabled then
        print(fullMessage)
    end
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

-- 接收客户端日志
RegisterNetEvent('lb-shoujika:log')
AddEventHandler('lb-shoujika:log', function(level, message)
    local sourceTag = string.format("[客户端-%d] ", source)
    local prefix = FormatTimestamp()
    local colorCode = GetColorCode(level)
    local resetCode = (Config and Config.Logging and Config.Logging.Console and Config.Logging.Console.Colors) and "^7" or ""
    local fullMessage = string.format("%s%s%s[LB-SHOUJIKA] %s: %s%s", 
        colorCode, prefix, sourceTag, level:upper(), message, resetCode)
    
    local consoleEnabled = true
    if Config and Config.Logging and Config.Logging.Console then
        consoleEnabled = Config.Logging.Console.Enabled ~= false
    end
    
    if consoleEnabled then
        print(fullMessage)
    end
end)

-- 接收客户端加载通知
RegisterNetEvent('lb-shoujika:clientLoaded')
AddEventHandler('lb-shoujika:clientLoaded', function()
    print("^2[LB-SHOUJIKA] 客户端脚本已加载 (玩家ID: " .. source .. ")^7")
end)

-- ============================================
-- 资源启动日志
-- ============================================
CreateThread(function()
    -- 立即输出启动信息（不依赖配置）
    print("^2============================================^7")
    print("^2[LB-SHOUJIKA] 服务器端脚本正在启动...^7")
    
    -- 检查ESX是否加载
    if not ESX then
        print("^1[LB-SHOUJIKA] 错误: ESX未加载！请确保es_extended资源已启动^7")
        return
    end
    
    Wait(3000) -- 等待资源完全加载，确保Config已加载
    
    -- 检查配置是否加载
    if not Config then
        print("^1[LB-SHOUJIKA] 错误: Config未加载！^7")
        print("^1[LB-SHOUJIKA] 请检查fxmanifest.lua中的shared_scripts配置^7")
        return
    end
    
    if not Config.Logging then
        print("^3[LB-SHOUJIKA] 警告: Config.Logging未找到，使用默认日志设置^7")
        -- 使用默认设置
        Config.Logging = {
            Enabled = true,
            Level = "info",
            ShowTimestamp = true,
            ShowSource = true,
            Console = { Enabled = true, Colors = true },
            F8 = { Enabled = true }
        }
    end
    
    -- 输出详细启动信息
    if Config.Logging.Enabled then
        LogInfo("============================================")
        LogInfo("LB手机运营商系统服务器端已启动")
        LogInfo("ESX框架: 已加载")
        LogInfo("日志系统: 已启用")
        LogInfo("日志级别: %s", Config.Logging.Level or "info")
        LogInfo("调试模式: %s", (Config.Debug and "开启" or "关闭"))
        LogInfo("时间戳: %s", (Config.Logging.ShowTimestamp and "开启" or "关闭"))
        LogInfo("颜色输出: %s", ((Config.Logging.Console and Config.Logging.Console.Colors) and "开启" or "关闭"))
        LogInfo("============================================")
        
        -- 测试日志输出
        LogInfo("测试日志: 这是一条测试信息")
        LogWarning("测试日志: 这是一条测试警告")
        LogError("测试日志: 这是一条测试错误")
    else
        print("^3[LB-SHOUJIKA] 警告: 日志系统未启用，请在config.lua中设置Config.Logging.Enabled = true^7")
    end
end)

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
-- 工具函数
-- ============================================

local function GetIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.identifier
    end
    return nil
end

-- 检查是否为管理员
local function IsAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- 检查管理员组
    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            return true
        end
    end
    
    -- 检查管理员许可证
    if Config.AdminLicenses and #Config.AdminLicenses > 0 then
        local playerLicense = nil
        for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
            if string.find(identifier, "license:") then
                playerLicense = identifier
                break
            end
        end
        
        if playerLicense then
            for _, adminLicense in ipairs(Config.AdminLicenses) do
                if playerLicense == adminLicense then
                    return true
                end
            end
        end
    end
    
    return false
end

-- 更新信用评分
local function UpdateCreditScore(phoneNumber, change, reason)
    if not phoneNumber or not change then return end
    
    local numberData = MySQL.single.await(
        "SELECT credit_score, credit_limit FROM phone_operator_numbers WHERE phone_number = ?",
        { phoneNumber }
    )
    
    if not numberData then return end
    
    local currentScore = numberData.credit_score or Config.Credit.CreditScore.InitialScore
    local newScore = math.max(
        Config.Credit.CreditScore.MinScore,
        math.min(Config.Credit.CreditScore.MaxScore, currentScore + change)
    )
    
    local newCreditLimit = Config.Credit.CreditFormula(newScore)
    
    MySQL.update.await(
        "UPDATE phone_operator_numbers SET credit_score = ?, credit_limit = ? WHERE phone_number = ?",
        { newScore, newCreditLimit, phoneNumber }
    )
    
    if Config.Debug then
        print(string.format("[LB-SHOUJIKA] 信用评分更新: %s, 变化: %d, 新评分: %d, 新额度: %d, 原因: %s",
            phoneNumber, change, newScore, newCreditLimit, reason or "未知"))
    end
    
    return newScore, newCreditLimit
end

-- 发送通知
local function Notify(source, title, message, type, duration)
    if not source or source == 0 then return end
    
    type = type or "info"
    duration = duration or Config.Notification.Duration
    
    -- 验证通知类型
    local validTypes = {
        ["info"] = true,
        ["success"] = true,
        ["error"] = true,
        ["warning"] = true
    }
    
    if not validTypes[type] then
        type = "info"
    end
    
    -- 根据配置的通知系统发送通知
    if Config.Notification.System == "okokNotify" then
        TriggerClientEvent('okokNotify:Alert', source, title, message, duration, type)
    elseif Config.Notification.System == "esx" then
        TriggerClientEvent('esx:showNotification', source, message)
    else
        -- 默认使用ESX通知
        TriggerClientEvent('esx:showNotification', source, message)
    end
end

-- 检测靓号并计算价格倍数
local function CheckPremiumNumber(phoneNumber)
    if not Config.PhoneNumber.PremiumNumbers.Enabled then
        return nil, 1.0
    end
    
    -- 提取号码主体（去除前缀）
    local body = phoneNumber
    for _, prefix in ipairs(Config.PhoneNumber.Prefixes) do
        if string.find(phoneNumber, "^" .. prefix) then
            body = string.sub(phoneNumber, #prefix + 1)
            break
        end
    end
    
    -- 检查所有靓号模式
    local bestMatch = nil
    local bestMultiplier = Config.PhoneNumber.PremiumNumbers.MinPriceMultiplier
    
    for _, pattern in ipairs(Config.PhoneNumber.PremiumNumbers.Patterns) do
        if string.match(body, pattern.pattern) then
            local multiplier = pattern.price_multiplier
            if multiplier > bestMultiplier then
                bestMultiplier = multiplier
                bestMatch = pattern
            end
        end
    end
    
    -- 限制倍数范围
    bestMultiplier = math.max(Config.PhoneNumber.PremiumNumbers.MinPriceMultiplier, 
                             math.min(Config.PhoneNumber.PremiumNumbers.MaxPriceMultiplier, bestMultiplier))
    
    return bestMatch, bestMultiplier
end

local function GeneratePhoneNumber(prefix)
    local prefixes = Config.PhoneNumber.Prefixes
    local ok, number
    
    while not ok do
        local body = ""
        for _ = 1, Config.PhoneNumber.Length do
            body = body .. tostring(math.random(0, 9))
        end
        
        if prefix then
            number = prefix .. body
        elseif #prefixes > 0 then
            number = prefixes[math.random(1, #prefixes)] .. body
        else
            number = body
        end
        
        local exists = MySQL.scalar.await(
            "SELECT phone_number FROM phone_operator_numbers WHERE phone_number = ?",
            { number }
        )
        ok = (exists == nil)
        if not ok then Wait(0) end
    end
    
    return number
end

-- ============================================
-- 获取套餐列表
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:getPackages', function(source, cb)
    LogDebug("玩家 %d 请求获取套餐列表", source)
    local packages = MySQL.query.await(
        "SELECT * FROM phone_operator_packages WHERE active = 1 ORDER BY price ASC"
    )
    LogDebug("返回 %d 个套餐", #(packages or {}))
    cb(packages or {})
end)

-- ============================================
-- 获取玩家的手机号列表
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:getMyNumbers', function(source, cb)
    local identifier = GetIdentifier(source)
    if not identifier then
        LogWarning("玩家 %d 标识符获取失败", source)
        return cb({})
    end
    
    LogDebug("玩家 %d (%s) 请求获取手机号列表", source, identifier)
    local numbers = MySQL.query.await(
        [[SELECT 
            n.*, 
            p.name as package_name, 
            p.description as package_description,
            p.weekly_fee,
            p.call_rate,
            p.sms_rate,
            p.data_rate
        FROM phone_operator_numbers n
        LEFT JOIN phone_operator_packages p ON n.package_id = p.id
        WHERE n.identifier = ? ORDER BY n.created_at DESC]],
        { identifier }
    )
    
    LogDebug("玩家 %d 有 %d 个手机号", source, #(numbers or {}))
    cb(numbers or {})
end)

-- ============================================
-- 购买手机号
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:purchaseNumber', function(source, cb, packageId)
    LogInfo("玩家 %d 请求购买手机号，套餐ID: %d", source, packageId)
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        LogError("玩家 %d 不存在", source)
        return cb(false, "玩家不存在")
    end
    
    local identifier = xPlayer.identifier
    
    -- 检查是否已有手机号
    if not Config.Purchase.AllowMultiple then
        local existing = MySQL.scalar.await(
            "SELECT phone_number FROM phone_operator_numbers WHERE identifier = ? AND status != 'expired'",
            { identifier }
        )
        if existing then
            LogWarning("玩家 %d 已拥有手机号: %s，不允许重复购买", source, existing)
            return cb(false, _U('purchase_already_owned'))
        end
    end
    
    -- 验证生成的手机号长度（普通玩家必须是7-15位）
    -- 注意：管理员可以通过命令设置1-7位号码，但普通玩家购买时生成的号码必须符合配置
    
    -- 获取套餐信息
    local package = MySQL.single.await(
        "SELECT * FROM phone_operator_packages WHERE id = ? AND active = 1",
        { packageId }
    )
    
    if not package then
        LogWarning("玩家 %d 请求的套餐不存在: ID=%d", source, packageId)
        return cb(false, _U('purchase_package_not_found'))
    end
    
    LogDebug("套餐信息: %s, 价格: $%d", package.name, package.price)
    
    -- 生成手机号
    local phoneNumber = GeneratePhoneNumber(package.phone_number_prefix)
    LogInfo("为玩家 %d 生成手机号: %s", source, phoneNumber)
    
    -- 检测靓号并计算价格
    local premiumMatch, priceMultiplier = CheckPremiumNumber(phoneNumber)
    local finalPrice = math.floor(package.price * priceMultiplier)
    
    if premiumMatch then
        LogInfo("检测到靓号: %s, 类型: %s, 价格倍数: %.2f, 最终价格: $%d", 
            phoneNumber, premiumMatch.name, priceMultiplier, finalPrice)
    end
    
    -- 如果是靓号，记录信息
    local premiumInfo = nil
    if premiumMatch then
        premiumInfo = {
            name = premiumMatch.name,
            multiplier = priceMultiplier,
            original_price = package.price,
            final_price = finalPrice
        }
        
        if Config.Debug then
            print(string.format("[LB-SHOUJIKA] 检测到靓号: %s, 类型: %s, 价格倍数: %.2f, 最终价格: $%d", 
                phoneNumber, premiumMatch.name, priceMultiplier, finalPrice))
        end
    end
    
    -- 检查余额
    local playerMoney = xPlayer.getMoney()
    if playerMoney < finalPrice then
        LogWarning("玩家 %d 余额不足: 需要 $%d, 当前 $%d", source, finalPrice, playerMoney)
        return cb(false, string.format(_U('purchase_insufficient_funds'), finalPrice) .. 
            (premiumMatch and string.format(" (" .. _U('purchase_premium_number', premiumMatch.name, priceMultiplier) .. ")") or ""))
    end
    
    -- 扣除费用
    xPlayer.removeMoney(finalPrice)
    LogInfo("从玩家 %d 扣除费用: $%d, 剩余: $%d", source, finalPrice, xPlayer.getMoney())
    
    -- 创建手机号记录（包含初始信用评分和信用额度）
    local status = Config.Purchase.AutoActivate and 'active' or 'inactive'
    local activatedAtValue = nil
    if Config.Purchase.AutoActivate then
        -- 将时间戳转换为MySQL日期时间格式 'YYYY-MM-DD HH:MM:SS'
        activatedAtValue = os.date('%Y-%m-%d %H:%M:%S', os.time())
    end
    local initialCreditScore = Config.Credit.CreditScore.InitialScore
    local initialCreditLimit = Config.Credit.CreditFormula(initialCreditScore)
    
    MySQL.insert.await(
        [[INSERT INTO phone_operator_numbers 
            (identifier, phone_number, package_id, balance, status, activated_at, credit_score, credit_limit) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)]],
        { identifier, phoneNumber, packageId, package.initial_balance, status, activatedAtValue, initialCreditScore, initialCreditLimit }
    )
    
    LogInfo("创建手机号记录: %s, 状态: %s, 余额: $%d, 信用评分: %d, 信用额度: $%d", 
        phoneNumber, status, package.initial_balance, initialCreditScore, initialCreditLimit)
    
    -- 发送购买成功通知
    if Config.Notifications.PurchaseSuccess then
        local message = string.format(_U('purchase_phone_number'), phoneNumber) .. ", " .. string.format(_U('purchase_initial_balance'), package.initial_balance)
        if premiumMatch then
            message = message .. "\n" .. string.format(_U('purchase_premium_number'), premiumMatch.name, priceMultiplier)
        end
        Notify(source, _U('notify_purchase_success'), message, "success")
    end
    
    -- 如果自动激活，创建或更新phone_phones记录
    if Config.Purchase.AutoActivate and Config.Purchase.ReplaceDefault then
        -- 获取所有可能的标识符格式（ESX可能使用不同的标识符格式）
        local identifiers = {}
        table.insert(identifiers, identifier) -- 主标识符
        
        -- 获取玩家的所有标识符
        local playerIdentifiers = GetPlayerIdentifiers(source)
        for _, ident in ipairs(playerIdentifiers) do
            -- 添加所有标识符（包括license、char1等格式）
            local found = false
            for _, existing in ipairs(identifiers) do
                if existing == ident then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(identifiers, ident)
            end
        end
        
        -- 更新所有可能的标识符格式
        for _, ident in ipairs(identifiers) do
            -- 检查是否已存在phone_phones记录
            local existingPhone = MySQL.scalar.await(
                "SELECT phone_number FROM phone_phones WHERE id = ? OR owner_id = ?",
                { ident, ident }
            )
            
            if existingPhone then
                -- 更新现有记录（更新所有匹配的记录）
                MySQL.update.await(
                    "UPDATE phone_phones SET phone_number = ? WHERE id = ? OR owner_id = ?",
                    { phoneNumber, ident, ident }
                )
            else
                -- 创建新记录（使用ON DUPLICATE KEY避免重复）
                MySQL.insert.await(
                    "INSERT INTO phone_phones (id, owner_id, phone_number, is_setup) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
                    { ident, ident, phoneNumber, 1, phoneNumber }
                )
            end
            
            -- 更新phone_last_phone（lb-phone使用此表获取当前号码）
            MySQL.update.await(
                "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
                { ident, phoneNumber, phoneNumber }
            )
        end
        
        -- 通知客户端刷新手机号
        if Config.Purchase.NotifyClient then
            TriggerClientEvent('lb-shoujika:phoneNumberUpdated', source, phoneNumber)
        end
        
        LogDebug("已更新手机号: %s, 标识符数量: %d", phoneNumber, #identifiers)
        for _, ident in ipairs(identifiers) do
            LogDebug("  - 标识符: %s", ident)
        end
    end
    
    -- 记录充值（初始余额）
    if package.initial_balance > 0 then
        MySQL.insert.await(
            [[INSERT INTO phone_operator_recharges 
                (phone_number, amount, balance_before, balance_after, method) 
                VALUES (?, ?, ?, ?, ?)]],
            { phoneNumber, package.initial_balance, 0, package.initial_balance, 'purchase' }
        )
        LogDebug("记录初始余额充值: $%d", package.initial_balance)
    end
    
    LogInfo("玩家 %d 购买手机号成功: %s", source, phoneNumber)
    cb(true, phoneNumber)
end)

-- ============================================
-- 激活手机号
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:activateNumber', function(source, cb, phoneNumber)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb(false, "玩家不存在")
    end
    
    local identifier = xPlayer.identifier
    
    -- 检查手机号是否属于该玩家
    local numberData = MySQL.single.await(
        "SELECT * FROM phone_operator_numbers WHERE phone_number = ? AND identifier = ?",
        { phoneNumber, identifier }
    )
    
    if not numberData then
        return cb(false, _U('activate_not_owned'))
    end
    
    if numberData.status == 'active' then
        return cb(false, _U('activate_already_active'))
    end
    
    -- 检查激活费用
    if Config.Activation.RequirePayment and Config.Activation.ActivationFee > 0 then
        if xPlayer.getMoney() < Config.Activation.ActivationFee then
            return cb(false, _U('activate_insufficient_funds'))
        end
        xPlayer.removeMoney(Config.Activation.ActivationFee)
    end
    
    -- 激活手机号
    local activatedAt = os.date('%Y-%m-%d %H:%M:%S', os.time())
    MySQL.update.await(
        "UPDATE phone_operator_numbers SET status = 'active', activated_at = ? WHERE phone_number = ?",
        { activatedAt, phoneNumber }
    )
    
    -- 替换默认手机号
    if Config.Purchase.ReplaceDefault then
        -- 获取所有可能的标识符格式
        local identifiers = {}
        table.insert(identifiers, identifier)
        
        local playerIdentifiers = GetPlayerIdentifiers(source)
        for _, ident in ipairs(playerIdentifiers) do
            local found = false
            for _, existing in ipairs(identifiers) do
                if existing == ident then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(identifiers, ident)
            end
        end
        
        -- 更新所有可能的标识符格式
        for _, ident in ipairs(identifiers) do
            -- 更新phone_phones表
            MySQL.update.await(
                "UPDATE phone_phones SET phone_number = ? WHERE id = ? OR owner_id = ?",
                { phoneNumber, ident, ident }
            )
            
            -- 如果不存在则创建
            MySQL.insert.await(
                "INSERT INTO phone_phones (id, owner_id, phone_number, is_setup) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
                { ident, ident, phoneNumber, 1, phoneNumber }
            )
            
            -- 更新phone_last_phone
            MySQL.update.await(
                "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
                { ident, phoneNumber, phoneNumber }
            )
        end
        
        -- 通知客户端刷新手机号
        if Config.Purchase.NotifyClient then
            TriggerClientEvent('lb-shoujika:phoneNumberUpdated', source, phoneNumber)
        end
    end
    
    Notify(source, _U('notify_activate_success'), _U('activate_success'), "success")
    cb(true)
end)

-- ============================================
-- 充值话费
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:rechargeBalance', function(source, cb, phoneNumber, amount, method)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb(false, "玩家不存在")
    end
    
    -- 验证金额
    if amount < Config.Recharge.MinAmount or amount > Config.Recharge.MaxAmount then
        return cb(false, _U('recharge_amount_invalid', Config.Recharge.MinAmount, Config.Recharge.MaxAmount))
    end
    
    -- 检查手机号
    local numberData = MySQL.single.await(
        "SELECT * FROM phone_operator_numbers WHERE phone_number = ?",
        { phoneNumber }
    )
    
    if not numberData then
        return cb(false, _U('recharge_phone_not_found'))
    end
    
    -- 验证充值方式
    if not Config.Recharge.Methods[method] then
        return cb(false, _U('recharge_method_not_supported', method))
    end
    
    -- 计算手续费和总费用
    local commission = 0
    if Config.Recharge.Commission > 0 then
        commission = math.floor(amount * Config.Recharge.Commission)
    end
    local totalCost = amount + commission
    
    -- 检查余额并扣除费用
    if method == 'cash' then
        if xPlayer.getMoney() < totalCost then
            return cb(false, _U('recharge_insufficient_cash'))
        end
        xPlayer.removeMoney(totalCost)
    elseif method == 'bank' then
        if xPlayer.getAccount('bank').money < totalCost then
            return cb(false, _U('recharge_insufficient_bank'))
        end
        xPlayer.removeAccountMoney('bank', totalCost)
    elseif method == 'card' then
        -- 银行卡充值（如果有实现）
        if xPlayer.getAccount('bank').money < totalCost then
            return cb(false, _U('recharge_insufficient_bank'))
        end
        xPlayer.removeAccountMoney('bank', totalCost)
    else
        return cb(false, _U('recharge_method_not_supported'))
    end
    
    -- 更新余额
    local newBalance = numberData.balance + amount
    local wasSuspended = (numberData.status == 'suspended')
    
    -- 检查是否需要恢复服务
    local newStatus = numberData.status
    if wasSuspended and Config.Balance.AutoResume and newBalance >= Config.Balance.ResumeThreshold then
        newStatus = 'active'
    end
    
    MySQL.update.await(
        "UPDATE phone_operator_numbers SET balance = ?, status = ?, last_recharge = NOW(), total_recharged = total_recharged + ? WHERE phone_number = ?",
        { newBalance, newStatus, amount, phoneNumber }
    )
    
    -- 如果服务已恢复，通知玩家
    if wasSuspended and newStatus == 'active' and Config.Notifications.ActivationSuccess then
        Notify(source, _U('notify_service_resumed'), 
            string.format(_U('recharge_current_balance'), newBalance), 
            "success")
    end
    
    -- 记录充值
    MySQL.insert.await(
        [[INSERT INTO phone_operator_recharges 
            (phone_number, amount, balance_before, balance_after, method) 
            VALUES (?, ?, ?, ?, ?)]],
        { phoneNumber, amount, numberData.balance, newBalance, method }
    )
    
    -- 更新信用评分（充值增加信用）
    if Config.Credit.CreditScore.RechargeAmount > 0 then
        local scoreIncrease = math.floor(amount * Config.Credit.CreditScore.RechargeAmount)
        if scoreIncrease > 0 then
            local newScore = math.min(
                Config.Credit.CreditScore.MaxScore,
                (numberData.credit_score or Config.Credit.CreditScore.InitialScore) + scoreIncrease
            )
            local newCreditLimit = Config.Credit.CreditFormula(newScore)
            
            MySQL.update.await(
                "UPDATE phone_operator_numbers SET credit_score = ?, credit_limit = ? WHERE phone_number = ?",
                { newScore, newCreditLimit, phoneNumber }
            )
            
            if Config.Notifications.CreditUpdate then
                Notify(source, _U('notify_credit_increased'), 
                    _U('credit_score_increased', amount, scoreIncrease, newCreditLimit), 
                    "info")
            end
        end
    end
    
    -- 发送充值成功通知
    if Config.Notifications.RechargeSuccess then
        local message = string.format(_U('recharge_current_balance'), newBalance)
        if commission > 0 then
            message = message .. "\n" .. _U('recharge_commission', amount, commission)
        end
        Notify(source, _U('notify_recharge_success'), message, "success")
    end
    
    cb(true, newBalance)
end)

-- ============================================
-- 获取话费余额
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:getBalance', function(source, cb, phoneNumber)
    local balance = MySQL.scalar.await(
        "SELECT balance FROM phone_operator_numbers WHERE phone_number = ?",
        { phoneNumber }
    )
    cb(balance or 0)
end)

-- 计算通话费用
local function CalculateCallCost(phoneNumber, duration, package)
    if not package then return 0 end
    
    -- 获取手机号信息
    local numberData = MySQL.single.await(
        "SELECT used_free_minutes, weekly_free_minutes_reset FROM phone_operator_numbers WHERE phone_number = ?",
        { phoneNumber }
    )
    
    if not numberData then return 0 end
    
    -- 检查免费分钟数重置
    local now = os.time()
    local resetTime = numberData.weekly_free_minutes_reset
    local usedFreeMinutes = numberData.used_free_minutes or 0
    local freeMinutes = package.free_minutes or 0
    
    -- 如果重置时间已过或不存在，重置免费分钟数
    if not resetTime or (now - resetTime) >= (7 * 24 * 60 * 60) then
        usedFreeMinutes = 0
        resetTime = os.date('%Y-%m-%d %H:%M:%S', now)
        MySQL.update.await(
            "UPDATE phone_operator_numbers SET used_free_minutes = 0, weekly_free_minutes_reset = ? WHERE phone_number = ?",
            { resetTime, phoneNumber }
        )
    end
    
    -- 计算通话分钟数
    local callMinutes = duration / 60
    if Config.CallBilling.RoundUp then
        callMinutes = math.ceil(callMinutes)
    else
        callMinutes = math.floor(callMinutes)
    end
    
    -- 计算费用
    local cost = 0
    local remainingFreeMinutes = math.max(0, freeMinutes - usedFreeMinutes)
    local chargeableMinutes = math.max(0, callMinutes - remainingFreeMinutes)
    
    if chargeableMinutes > 0 then
        cost = math.floor(chargeableMinutes * (package.call_rate or 0) * 100) -- 转换为分
    end
    
    -- 更新已使用的免费分钟数
    local newUsedFreeMinutes = math.min(freeMinutes, usedFreeMinutes + callMinutes)
    MySQL.update.await(
        "UPDATE phone_operator_numbers SET used_free_minutes = ? WHERE phone_number = ?",
        { newUsedFreeMinutes, phoneNumber }
    )
    
    return cost, chargeableMinutes, (callMinutes - chargeableMinutes)
end

-- 检查是否可以拨打电话
local function CanMakeCall(phoneNumber)
    if not Config.CallBilling.CheckBeforeCall then
        return true
    end
    
    local numberData = MySQL.single.await(
        "SELECT balance, credit_limit, status FROM phone_operator_numbers WHERE phone_number = ?",
        { phoneNumber }
    )
    
    if not numberData or numberData.status ~= 'active' then
        return false, "手机号未激活或已暂停"
    end
    
    -- 检查是否有余额或信用额度
    local availableBalance = numberData.balance + (numberData.credit_limit or 0)
    if availableBalance <= 0 then
        if Config.CallBilling.BlockOnOverdue then
            return false, "余额不足，无法拨打电话"
        end
    end
    
    return true
end

-- ============================================
-- 扣除话费（供lb-phone调用）
-- ============================================
-- 通话计费导出函数（供lb-phone调用）
exports('chargeCall', function(phoneNumber, duration, calleeNumber)
    if not phoneNumber or not duration or duration <= 0 then
        return false, "参数错误"
    end
    
    -- 检查是否可以拨打电话
    local canCall, errorMsg = CanMakeCall(phoneNumber)
    if not canCall then
        return false, errorMsg
    end
    
    -- 获取套餐信息
    local numberData = MySQL.single.await(
        [[SELECT n.*, p.call_rate, p.free_minutes 
          FROM phone_operator_numbers n
          LEFT JOIN phone_operator_packages p ON n.package_id = p.id
          WHERE n.phone_number = ? AND n.status = 'active']],
        { phoneNumber }
    )
    
    if not numberData then
        return false, "手机号不存在或未激活"
    end
    
    -- 计算通话费用
    local cost, chargeableMinutes, freeMinutes = CalculateCallCost(phoneNumber, duration, numberData)
    
    if cost > 0 then
        -- 扣除费用
        local success, newBalance = exports['lb-shoujika']:chargeBalance(
            phoneNumber,
            cost,
            'call',
            string.format('通话费用 (%d分钟)', chargeableMinutes),
            {
                duration = duration,
                callee = calleeNumber,
                chargeable_minutes = chargeableMinutes,
                free_minutes = freeMinutes
            }
        )
        
        if not success then
            return false, "扣费失败"
        end
        
        -- 记录通话日志
        MySQL.insert.await(
            [[INSERT INTO phone_operator_call_logs 
                (phone_number, callee_number, duration, charge_amount, used_free_minutes) 
                VALUES (?, ?, ?, ?, ?)]],
            { phoneNumber, calleeNumber or '', duration, cost, freeMinutes > 0 }
        )
        
        return true, newBalance
    else
        -- 免费通话，只记录日志
        MySQL.insert.await(
            [[INSERT INTO phone_operator_call_logs 
                (phone_number, callee_number, duration, charge_amount, used_free_minutes) 
                VALUES (?, ?, ?, ?, ?)]],
            { phoneNumber, calleeNumber or '', duration, 0, true }
        )
        
        return true, numberData.balance
    end
end)

exports('chargeBalance', function(phoneNumber, amount, chargeType, description, metadata)
    if not phoneNumber or not amount or amount <= 0 then
        return false
    end
    
    local numberData = MySQL.single.await(
        "SELECT * FROM phone_operator_numbers WHERE phone_number = ? AND status = 'active'",
        { phoneNumber }
    )
    
    if not numberData then
        return false
    end
    
    -- 检查余额和信用额度
    local availableBalance = numberData.balance + (numberData.credit_limit or 0)
    
    if availableBalance < amount then
        -- 余额和信用额度都不足
        if Config.Balance.AutoSuspend and numberData.balance <= Config.Balance.AutoSuspendThreshold then
            MySQL.update.await(
                "UPDATE phone_operator_numbers SET status = 'suspended' WHERE phone_number = ?",
                { phoneNumber }
            )
            
            -- 欠费扣信用评分
            if Config.Credit.CreditScore.OverduePenalty < 0 then
                UpdateCreditScore(phoneNumber, Config.Credit.CreditScore.OverduePenalty, "欠费暂停服务")
            end
        end
        return false
    end
    
    -- 如果余额不足但信用额度足够，使用信用额度
    local balanceUsed = math.min(numberData.balance, amount)
    local creditUsed = amount - balanceUsed
    
    if creditUsed > 0 then
        -- 使用信用额度，扣信用评分
        if Config.Credit.CreditScore.LatePayment < 0 then
            UpdateCreditScore(phoneNumber, Config.Credit.CreditScore.LatePayment, "使用信用额度")
        end
    end
    
    local newBalance = numberData.balance - balanceUsed
    -- 如果使用了信用额度，需要更新信用额度使用情况
    MySQL.update.await(
        "UPDATE phone_operator_numbers SET balance = ?, total_spent = total_spent + ? WHERE phone_number = ?",
        { newBalance, amount, phoneNumber }
    )
    
    -- 记录消费
    MySQL.insert.await(
        [[INSERT INTO phone_operator_charges 
            (phone_number, type, amount, balance_before, balance_after, description, metadata) 
            VALUES (?, ?, ?, ?, ?, ?, ?)]],
        { phoneNumber, chargeType or 'other', amount, numberData.balance, newBalance, description, json.encode(metadata or {}) }
    )
    
    -- 低余额警告和自动暂停
    if newBalance <= Config.Balance.LowBalanceWarning then
        local ownerSrc = nil
        -- 查找在线玩家
        for _, playerId in ipairs(GetPlayers()) do
            local playerIdentifier = GetIdentifier(tonumber(playerId))
            if playerIdentifier == numberData.identifier then
                ownerSrc = tonumber(playerId)
                break
            end
        end
        
        -- 低余额警告
        if Config.Notifications.LowBalance and ownerSrc then
            Notify(ownerSrc, _U('notify_low_balance'), 
                _U('balance_low_warning', newBalance), 
                "warning")
        end
        
        -- 自动暂停服务
        if Config.Balance.AutoSuspend and newBalance <= Config.Balance.AutoSuspendThreshold then
            if numberData.status ~= 'suspended' then
                MySQL.update.await(
                    "UPDATE phone_operator_numbers SET status = 'suspended' WHERE phone_number = ?",
                    { phoneNumber }
                )
                
                if ownerSrc then
                    Notify(ownerSrc, _U('notify_service_suspended'), 
                        _U('balance_auto_suspend', newBalance), 
                        "error")
                end
                
                if Config.Debug then
                    print(string.format("[LB-SHOUJIKA] 自动暂停服务: %s, 余额: $%d", phoneNumber, newBalance))
                end
            end
        end
    end
    
    return true, newBalance
end)

-- ============================================
-- 获取充值记录
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:getRechargeHistory', function(source, cb, phoneNumber, limit)
    limit = limit or 20
    local history = MySQL.query.await(
        "SELECT * FROM phone_operator_recharges WHERE phone_number = ? ORDER BY created_at DESC LIMIT ?",
        { phoneNumber, limit }
    )
    cb(history or {})
end)

-- ============================================
-- 获取消费记录
-- ============================================
ESX.RegisterServerCallback('lb-shoujika:getChargeHistory', function(source, cb, phoneNumber, limit)
    limit = limit or 20
    local history = MySQL.query.await(
        "SELECT * FROM phone_operator_charges WHERE phone_number = ? ORDER BY created_at DESC LIMIT ?",
        { phoneNumber, limit }
    )
    cb(history or {})
end)

-- ============================================
-- 管理员命令：修改玩家手机号（支持1-7位，可指定套餐）
-- ============================================
RegisterCommand(Config.AdminCommands.Command, function(source, args)
    if not Config.AdminCommands.Enabled then
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end
    
    -- 检查权限
    if not IsAdmin(source) then
        Notify(source, _U('error'), _U('admin_no_permission'), "error")
        return
    end
    
    -- 检查参数
    if #args < 2 then
        Notify(source, _U('admin_command_format_error'), 
            string.format("用法: /%s [玩家ID] [新手机号] [套餐ID(可选)]\n示例: /%s 1 1234567 2", 
                Config.AdminCommands.Command, Config.AdminCommands.Command), 
            "error")
        return
    end
    
    local targetId = tonumber(args[1])
    local newPhoneNumber = args[2]
    local packageId = tonumber(args[3]) or 1 -- 默认套餐ID为1
    
    if not targetId or not newPhoneNumber then
        Notify(source, _U('error'), _U('admin_command_format_error'), "error")
        return
    end
    
    -- 验证手机号格式（管理员可设置1-7位）
    local phoneLength = #newPhoneNumber
    if phoneLength < Config.AdminCommands.MinPhoneLength or phoneLength > Config.AdminCommands.MaxPhoneLength then
        Notify(source, _U('admin_phone_number_format_error'), 
            _U('admin_phone_number_length_error', Config.AdminCommands.MinPhoneLength, Config.AdminCommands.MaxPhoneLength), 
            "error")
        return
    end
    
    -- 验证手机号只包含数字
    if not string.match(newPhoneNumber, "^%d+$") then
        Notify(source, _U('admin_phone_number_format_error'), _U('admin_phone_number_digits_only'), "error")
        return
    end
    
    -- 验证套餐是否存在
    local package = MySQL.single.await(
        "SELECT * FROM phone_operator_packages WHERE id = ?",
        { packageId }
    )
    
    if not package then
        Notify(source, _U('admin_package_not_found'), string.format("套餐ID %d 不存在", packageId), "error")
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        Notify(source, _U('admin_player_not_found'), string.format("ID %d 的玩家不在线", targetId), "error")
        return
    end
    
    local targetIdentifier = targetPlayer.identifier
    
    -- 检查新手机号是否已被使用
    local existing = MySQL.scalar.await(
        "SELECT phone_number FROM phone_operator_numbers WHERE phone_number = ?",
        { newPhoneNumber }
    )
    
    if existing then
        Notify(source, _U('admin_phone_number_used'), string.format("手机号 %s 已被其他玩家使用", newPhoneNumber), "error")
        return
    end
    
    -- 检查phone_phones表中是否已存在
    local existingPhone = MySQL.scalar.await(
        "SELECT phone_number FROM phone_phones WHERE phone_number = ?",
        { newPhoneNumber }
    )
    
    if existingPhone then
        Notify(source, _U('admin_phone_number_used'), string.format("手机号 %s 在系统中已被使用", newPhoneNumber), "error")
        return
    end
    
    -- 获取玩家当前的手机号记录
    local currentNumber = MySQL.single.await(
        "SELECT * FROM phone_operator_numbers WHERE identifier = ? AND status = 'active' LIMIT 1",
        { targetIdentifier }
    )
    
    if currentNumber then
        -- 更新现有记录（包括套餐）
        MySQL.update.await(
            "UPDATE phone_operator_numbers SET phone_number = ?, package_id = ? WHERE id = ?",
            { newPhoneNumber, packageId, currentNumber.id }
        )
    else
        -- 创建新记录（使用指定套餐）
        local initialCreditScore = Config.Credit.CreditScore.InitialScore
        local initialCreditLimit = Config.Credit.CreditFormula(initialCreditScore)
        
        local activatedAt = os.date('%Y-%m-%d %H:%M:%S', os.time())
        MySQL.insert.await(
            [[INSERT INTO phone_operator_numbers 
                (identifier, phone_number, package_id, balance, status, activated_at, credit_score, credit_limit) 
                VALUES (?, ?, ?, ?, 'active', ?, ?, ?)]],
            { targetIdentifier, newPhoneNumber, packageId, package.initial_balance or 0, activatedAt, initialCreditScore, initialCreditLimit }
        )
    end
    
    -- 获取目标玩家的所有标识符格式
    local identifiers = {}
    table.insert(identifiers, targetIdentifier)
    
    local playerIdentifiers = GetPlayerIdentifiers(targetId)
    for _, ident in ipairs(playerIdentifiers) do
        local found = false
        for _, existing in ipairs(identifiers) do
            if existing == ident then
                found = true
                break
            end
        end
        if not found then
            table.insert(identifiers, ident)
        end
    end
    
    -- 更新所有可能的标识符格式
    for _, ident in ipairs(identifiers) do
        -- 更新phone_phones表
        MySQL.update.await(
            "UPDATE phone_phones SET phone_number = ? WHERE id = ? OR owner_id = ?",
            { newPhoneNumber, ident, ident }
        )
        
        -- 如果不存在则创建
        MySQL.insert.await(
            "INSERT INTO phone_phones (id, owner_id, phone_number, is_setup) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
            { ident, ident, newPhoneNumber, 1, newPhoneNumber }
        )
        
        -- 更新phone_last_phone
        MySQL.update.await(
            "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
            { ident, newPhoneNumber, newPhoneNumber }
        )
    end
    
    -- 通知目标玩家客户端刷新手机号
    if Config.Purchase.NotifyClient then
        TriggerClientEvent('lb-shoujika:phoneNumberUpdated', targetId, newPhoneNumber)
    end
    
    -- 通知管理员
    Notify(source, _U('admin_operation_success'), 
        string.format("已将玩家 %s (ID: %d) 的手机号修改为: %s\n套餐: %s (ID: %d)", 
            targetPlayer.getName(), targetId, newPhoneNumber, package.name, packageId), 
        "success")
    
    -- 通知目标玩家
    if targetId ~= source then
        Notify(targetId, _U('admin_phone_updated'), 
            string.format("管理员已将您的手机号修改为: %s\n套餐: %s", newPhoneNumber, package.name), 
            "info")
    end
    
    -- 记录日志
    print(string.format("[LB-SHOUJIKA] 管理员 %s (ID: %d) 将玩家 %s (ID: %d) 的手机号修改为: %s，套餐: %s (ID: %d)",
        xPlayer.getName(), source, targetPlayer.getName(), targetId, newPhoneNumber, package.name, packageId))
end, false)

-- ============================================
-- 管理员命令：设置玩家信用额度
-- ============================================
RegisterCommand(Config.AdminCreditCommand.Command, function(source, args)
    if not Config.AdminCreditCommand.Enabled then
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end
    
    -- 检查权限
    if not IsAdmin(source) then
        Notify(source, "权限不足", "您没有权限使用此命令", "error")
        return
    end
    
    -- 检查参数
    if #args < 2 then
        Notify(source, "命令格式错误", 
            string.format("用法: /%s [玩家ID] [信用额度(分)]\n示例: /%s 1 10000 (设置100元信用额度)", 
                Config.AdminCreditCommand.Command, Config.AdminCreditCommand.Command), 
            "error")
        return
    end
    
    local targetId = tonumber(args[1])
    local creditLimit = tonumber(args[2])
    
    if not targetId or not creditLimit then
        Notify(source, "参数错误", "玩家ID和信用额度必须是有效数字", "error")
        return
    end
    
    -- 验证信用额度范围
    if creditLimit < Config.Credit.MinCredit or creditLimit > Config.Credit.MaxCredit then
        Notify(source, "信用额度错误", 
            string.format("信用额度必须在 %d - %d 之间", 
                Config.Credit.MinCredit, Config.Credit.MaxCredit), 
            "error")
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        Notify(source, "玩家不存在", string.format("ID %d 的玩家不在线", targetId), "error")
        return
    end
    
    local targetIdentifier = targetPlayer.identifier
    
    -- 获取玩家当前的手机号记录
    local currentNumber = MySQL.single.await(
        "SELECT * FROM phone_operator_numbers WHERE identifier = ? AND status = 'active' LIMIT 1",
        { targetIdentifier }
    )
    
    if not currentNumber then
        Notify(source, "玩家没有手机号", "该玩家还没有激活的手机号", "error")
        return
    end
    
    -- 计算对应的信用评分（反向计算）
    local creditScore = math.floor(creditLimit / 10) -- 根据公式 credit_limit = credit_score * 10
    
    -- 更新信用额度和信用评分
    MySQL.update.await(
        "UPDATE phone_operator_numbers SET credit_limit = ?, credit_score = ? WHERE phone_number = ?",
        { creditLimit, creditScore, currentNumber.phone_number }
    )
    
    -- 通知管理员
    Notify(source, "操作成功", 
        string.format("已将玩家 %s (ID: %d) 的信用额度设置为: $%d (信用评分: %d)", 
            targetPlayer.getName(), targetId, creditLimit, creditScore), 
        "success")
    
    -- 通知目标玩家
    if targetId ~= source then
        Notify(targetId, "信用额度已更新", 
            string.format("管理员已将您的信用额度设置为: $%d", creditLimit), 
            "info")
    end
    
    -- 记录日志
    print(string.format("[LB-SHOUJIKA] 管理员 %s (ID: %d) 将玩家 %s (ID: %d) 的信用额度设置为: $%d (信用评分: %d)",
        xPlayer.getName(), source, targetPlayer.getName(), targetId, creditLimit, creditScore))
end, false)

-- ============================================
-- 管理员命令：对指定号码充值话费
-- ============================================
RegisterCommand(Config.AdminRechargeCommand.Command, function(source, args)
    if not Config.AdminRechargeCommand.Enabled then
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end
    
    -- 检查权限
    if not IsAdmin(source) then
        Notify(source, "权限不足", "您没有权限使用此命令", "error")
        return
    end
    
    -- 检查参数
    if #args < 2 then
        Notify(source, "命令格式错误", 
            string.format("用法: /%s [手机号] [充值金额(分)]\n示例: /%s 1234567 10000 (充值100元)", 
                Config.AdminRechargeCommand.Command, Config.AdminRechargeCommand.Command), 
            "error")
        return
    end
    
    local phoneNumber = args[1]
    local amount = tonumber(args[2])
    
    if not phoneNumber or not amount or amount <= 0 then
        Notify(source, "参数错误", "手机号和充值金额必须是有效值", "error")
        return
    end
    
    -- 验证充值金额范围
    if amount < Config.Recharge.MinAmount or amount > Config.Recharge.MaxAmount then
        Notify(source, "充值金额错误", 
            string.format("充值金额必须在 %d - %d 之间", 
                Config.Recharge.MinAmount, Config.Recharge.MaxAmount), 
            "error")
        return
    end
    
    -- 检查手机号是否存在
    local numberData = MySQL.single.await(
        "SELECT * FROM phone_operator_numbers WHERE phone_number = ?",
        { phoneNumber }
    )
    
    if not numberData then
        Notify(source, "手机号不存在", string.format("手机号 %s 不存在", phoneNumber), "error")
        return
    end
    
    -- 更新余额
    local newBalance = numberData.balance + amount
    local wasSuspended = (numberData.status == 'suspended')
    
    -- 检查是否需要恢复服务
    local newStatus = numberData.status
    if wasSuspended and Config.Balance.AutoResume and newBalance >= Config.Balance.ResumeThreshold then
        newStatus = 'active'
    end
    
    MySQL.update.await(
        "UPDATE phone_operator_numbers SET balance = ?, status = ?, last_recharge = NOW(), total_recharged = total_recharged + ? WHERE phone_number = ?",
        { newBalance, newStatus, amount, phoneNumber }
    )
    
    -- 记录充值
    MySQL.insert.await(
        [[INSERT INTO phone_operator_recharges 
            (phone_number, amount, balance_before, balance_after, method) 
            VALUES (?, ?, ?, ?, ?)]],
        { phoneNumber, amount, numberData.balance, newBalance, 'admin' }
    )
    
    -- 更新信用评分（充值增加信用）
    if Config.Credit.CreditScore.RechargeAmount > 0 then
        local scoreIncrease = math.floor(amount * Config.Credit.CreditScore.RechargeAmount)
        if scoreIncrease > 0 then
            local newScore = math.min(
                Config.Credit.CreditScore.MaxScore,
                (numberData.credit_score or Config.Credit.CreditScore.InitialScore) + scoreIncrease
            )
            local newCreditLimit = Config.Credit.CreditFormula(newScore)
            
            MySQL.update.await(
                "UPDATE phone_operator_numbers SET credit_score = ?, credit_limit = ? WHERE phone_number = ?",
                { newScore, newCreditLimit, phoneNumber }
            )
        end
    end
    
    -- 通知管理员
    local message = string.format("已为手机号 %s 充值 $%d\n当前余额：$%d", phoneNumber, amount, newBalance)
    if wasSuspended and newStatus == 'active' then
        message = message .. "\n服务已自动恢复"
    end
    Notify(source, "充值成功", message, "success")
    
    -- 查找并通知号码所有者（如果在线）
    for _, playerId in ipairs(GetPlayers()) do
        local playerIdentifier = GetIdentifier(tonumber(playerId))
        if playerIdentifier == numberData.identifier then
            local ownerSrc = tonumber(playerId)
            if ownerSrc then
                local ownerMessage = string.format("管理员已为您的手机号充值 $%d\n当前余额：$%d", amount, newBalance)
                if wasSuspended and newStatus == 'active' then
                    ownerMessage = ownerMessage .. "\n服务已自动恢复"
                end
                Notify(ownerSrc, "话费已充值", ownerMessage, "success")
            end
            break
        end
    end
    
    -- 记录日志
    print(string.format("[LB-SHOUJIKA] 管理员 %s (ID: %d) 为手机号 %s 充值 $%d，余额：$%d -> $%d",
        xPlayer.getName(), source, phoneNumber, amount, numberData.balance, newBalance))
end, false)

-- ============================================
-- 周租费自动扣除（定时任务）
-- ============================================
CreateThread(function()
    while true do
        Wait(3600000) -- 每小时检查一次
        
        local numbers = MySQL.query.await(
            "SELECT * FROM phone_operator_numbers WHERE status = 'active'"
        )
        
        if numbers then
            for _, numberData in ipairs(numbers) do
                local package = MySQL.single.await(
                    "SELECT weekly_fee FROM phone_operator_packages WHERE id = ?",
                    { numberData.package_id }
                )
                
                if package and package.weekly_fee > 0 then
                    -- 检查是否到了扣费时间（每周）
                    local currentTime = os.time()
                    local lastCharge = numberData.last_weekly_fee or numberData.activated_at
                    
                    if lastCharge then
                        local daysSince = math.floor((currentTime - lastCharge) / 86400)
                        if daysSince >= 7 then
                            exports['lb-shoujika']:chargeBalance(
                                numberData.phone_number,
                                package.weekly_fee,
                                'weekly_fee',
                                '周租费',
                                {}
                            )
                            
                            MySQL.update.await(
                                "UPDATE phone_operator_numbers SET last_weekly_fee = NOW() WHERE phone_number = ?",
                                { numberData.phone_number }
                            )
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================
-- 自动收回欠费号码（定时任务）
-- ============================================
CreateThread(function()
    while true do
        Wait(Config.AutoReclaim.CheckInterval or 3600000) -- 默认每小时检查一次
        
        if not Config.AutoReclaim.Enabled then
            Wait(Config.AutoReclaim.CheckInterval or 3600000)
            goto continue
        end
        
        -- 查找所有欠费且状态为suspended或overdue的号码
        -- 使用UNIX_TIMESTAMP获取时间戳，方便计算天数
        local overdueNumbers = MySQL.query.await(
            [[SELECT n.*, p.name as package_name,
              UNIX_TIMESTAMP(n.last_recharge) as last_recharge_timestamp
              FROM phone_operator_numbers n
              LEFT JOIN phone_operator_packages p ON n.package_id = p.id
              WHERE n.status IN ('suspended', 'overdue') 
              AND n.balance < 0
              AND n.last_recharge IS NOT NULL]]
        )
        
        if overdueNumbers then
            local currentTime = os.time()
            
            for _, numberData in ipairs(overdueNumbers) do
                -- 计算欠费天数
                local rechargeTimestamp = numberData.last_recharge_timestamp
                if not rechargeTimestamp or rechargeTimestamp == 0 then
                    -- 如果没有时间戳，跳过此号码
                    goto continue_number
                end
                
                local daysOverdue = math.floor((currentTime - rechargeTimestamp) / 86400)
                
                -- 检查是否达到收回天数
                if daysOverdue >= Config.AutoReclaim.OverdueDays then
                    -- 收回前通知（如果启用）
                    if Config.AutoReclaim.NotifyBeforeReclaim and 
                       daysOverdue == Config.AutoReclaim.OverdueDays then
                        -- 查找在线玩家并通知
                        for _, playerId in ipairs(GetPlayers()) do
                            local playerIdentifier = GetIdentifier(tonumber(playerId))
                            if playerIdentifier == numberData.identifier then
                                local ownerSrc = tonumber(playerId)
                                if ownerSrc then
                                    Notify(ownerSrc, "号码即将被收回", 
                                        string.format("您的手机号 %s 已欠费 %d 天，即将被收回。请及时充值！", 
                                            numberData.phone_number, daysOverdue), 
                                        "warning")
                                end
                                break
                            end
                        end
                    end
                    
                    -- 执行收回
                    if daysOverdue >= Config.AutoReclaim.OverdueDays then
                        -- 更新状态为已过期
                        MySQL.update.await(
                            "UPDATE phone_operator_numbers SET status = ? WHERE phone_number = ?",
                            { Config.AutoReclaim.ReclaimStatus, numberData.phone_number }
                        )
                        
                        -- 从phone_phones表中移除（释放号码）
                        MySQL.update.await(
                            "UPDATE phone_phones SET phone_number = NULL WHERE phone_number = ?",
                            { numberData.phone_number }
                        )
                        
                        -- 从phone_last_phone表中移除
                        MySQL.update.await(
                            "DELETE FROM phone_last_phone WHERE phone_number = ?",
                            { numberData.phone_number }
                        )
                        
                        -- 查找并通知号码所有者（如果在线）
                        for _, playerId in ipairs(GetPlayers()) do
                            local playerIdentifier = GetIdentifier(tonumber(playerId))
                            if playerIdentifier == numberData.identifier then
                                local ownerSrc = tonumber(playerId)
                                if ownerSrc then
                                    Notify(ownerSrc, "号码已被收回", 
                                        string.format("您的手机号 %s 因欠费 %d 天未充值已被收回", 
                                            numberData.phone_number, daysOverdue), 
                                        "error")
                                end
                                break
                            end
                        end
                        
                        -- 记录日志
                        print(string.format("[LB-SHOUJIKA] 自动收回号码: %s, 所有者: %s, 欠费天数: %d, 余额: $%d",
                            numberData.phone_number, numberData.identifier, daysOverdue, numberData.balance))
                    end
                end
                ::continue_number::
            end
        end
        
        ::continue::
    end
end)

