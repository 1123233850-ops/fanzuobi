local MySQL = MySQL

Database = {}

-- 白名单缓存
local whitelistCache = {}

-- 上次更新白名单缓存的时间
local lastWhitelistUpdate = 0

-- 白名单缓存更新间隔（秒）
local WHITELIST_CACHE_INTERVAL = 300 -- 5分钟更新一次

-- 检查数据库连接状态
function Database.CheckConnection()
    local success, result = pcall(function()
        return MySQL.Sync.fetchScalar('SELECT 1')
    end)
    
    if success then
        print('[XD ACE] 数据库连接正常')
        return true
    else
        print('[XD ACE] 数据库连接失败: ' .. tostring(result))
        return false
    end
end

-- 检查数据库是否存在
function Database.CheckDatabaseExists()
    local databaseName = GetConvar('mysql_database', 'fivem')
    local success, result = pcall(function()
        return MySQL.Sync.fetchAll([[
            SELECT SCHEMA_NAME 
            FROM INFORMATION_SCHEMA.SCHEMATA 
            WHERE SCHEMA_NAME = ?
        ]], {databaseName})
    end)
    
    return success and #result > 0
end

-- 创建数据库（如果不存在）
function Database.CreateDatabase()
    local databaseName = GetConvar('mysql_database', 'fivem')
    
    -- 验证数据库名合法性，防止SQL注入
    if not string.match(databaseName, '^[a-zA-Z0-9_-]+$') then
        print('[XD ACE] 错误: 无效的数据库名格式')
        return false
    end
    
    print('[XD ACE] 正在创建数据库: ' .. databaseName)
    
    local success, result = pcall(function()
        return MySQL.Sync.execute([[
            CREATE DATABASE IF NOT EXISTS `]] .. databaseName .. [[` 
            CHARACTER SET utf8mb4 
            COLLATE utf8mb4_unicode_ci
        ]])
    end)
    
    if success then
        print('[XD ACE] 数据库创建/验证成功')
        return true
    else
        print('[XD ACE] 数据库创建失败: ' .. tostring(result))
        return false
    end
end

-- 初始化数据库表
function Database.InitTables()
    local tablesCreated = 0
    local errors = {}
    
    -- 封禁表
    local success1, result1 = pcall(function()
        return MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `xd_ace_bans` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `license` VARCHAR(255) NOT NULL,
                `discord` VARCHAR(255) DEFAULT NULL,
                `ip` VARCHAR(255) DEFAULT NULL,
                `player_name` VARCHAR(255) NOT NULL,
                `reason` TEXT NOT NULL,
                `ban_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                `unban_date` TIMESTAMP NULL,
                `banned_by` VARCHAR(255) DEFAULT 'XD ACE Anti-Cheat',
                `evidence` LONGTEXT DEFAULT NULL,
                `ban_type` ENUM('temporary', 'permanent') DEFAULT 'temporary',
                `is_active` BOOLEAN DEFAULT TRUE,
                INDEX `license_idx` (`license`),
                INDEX `discord_idx` (`discord`),
                INDEX `ip_idx` (`ip`),
                INDEX `active_idx` (`is_active`),
                INDEX `ban_date_idx` (`ban_date`),
                INDEX `unban_date_idx` (`unban_date`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], {})
    end)
    
    if success1 then
        tablesCreated = tablesCreated + 1
        print('[XD ACE] 封禁表初始化成功')
    else
        table.insert(errors, "封禁表: " .. tostring(result1))
    end
    
    -- 违规日志表
    local success2, result2 = pcall(function()
        return MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `xd_ace_violations` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `license` VARCHAR(255) NOT NULL,
                `player_name` VARCHAR(255) NOT NULL,
                `violation_type` VARCHAR(100) NOT NULL,
                `violation_data` LONGTEXT NOT NULL,
                `severity` ENUM('low', 'medium', 'high') DEFAULT 'medium',
                `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                `processed` BOOLEAN DEFAULT FALSE,
                INDEX `license_idx` (`license`),
                INDEX `type_idx` (`violation_type`),
                INDEX `timestamp_idx` (`timestamp`),
                INDEX `severity_idx` (`severity`),
                INDEX `processed_idx` (`processed`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], {})
    end)
    
    if success2 then
        tablesCreated = tablesCreated + 1
        print('[XD ACE] 违规日志表初始化成功')
    else
        table.insert(errors, "违规日志表: " .. tostring(result2))
    end
    
    -- 管理员表
    local success3, result3 = pcall(function()
        return MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `xd_ace_admins` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `username` VARCHAR(50) NOT NULL UNIQUE,
                `password_hash` VARCHAR(255) NOT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX `username_idx` (`username`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], {})
    end)
    
    if success3 then
        tablesCreated = tablesCreated + 1
        print('[XD ACE] 管理员表初始化成功')
    else
        table.insert(errors, "管理员表: " .. tostring(result3))
    end
    
    -- 白名单表
    local success4, result4 = pcall(function()
        return MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `xd_ace_whitelist` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `license` VARCHAR(255) NOT NULL UNIQUE,
                `discord` VARCHAR(255) DEFAULT NULL,
                `player_name` VARCHAR(255) NOT NULL,
                `added_by` VARCHAR(255) NOT NULL,
                `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                `notes` TEXT DEFAULT NULL,
                INDEX `license_idx` (`license`),
                INDEX `discord_idx` (`discord`),
                INDEX `added_date_idx` (`added_date`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], {})
    end)
    
    if success4 then
        tablesCreated = tablesCreated + 1
        print('[XD ACE] 白名单表初始化成功')
    else
        table.insert(errors, "白名单表: " .. tostring(result4))
    end
    
    -- 管理员操作日志表
    local success5, result5 = pcall(function()
        return MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `xd_ace_admin_logs` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `admin_license` VARCHAR(255) NOT NULL,
                `admin_name` VARCHAR(255) NOT NULL,
                `action` VARCHAR(100) NOT NULL,
                `target_license` VARCHAR(255) DEFAULT NULL,
                `target_name` VARCHAR(255) DEFAULT NULL,
                `details` TEXT DEFAULT NULL,
                `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX `admin_idx` (`admin_license`),
                INDEX `target_idx` (`target_license`),
                INDEX `action_idx` (`action`),
                INDEX `timestamp_idx` (`timestamp`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], {})
    end)
    
    if success5 then
        tablesCreated = tablesCreated + 1
        print('[XD ACE] 管理员操作日志表初始化成功')
    else
        table.insert(errors, "管理员操作日志表: " .. tostring(result5))
    end
    
    -- 返回结果
    return {
        success = #errors == 0,
        tablesCreated = tablesCreated,
        errors = errors
    }
end

-- 检查表结构完整性
function Database.VerifyTableStructure()
    local requiredTables = {
        'xd_ace_bans',
        'xd_ace_violations', 
        'xd_ace_whitelist',
        'xd_ace_admin_logs'
    }
    
    local missingTables = {}
    
    for _, tableName in ipairs(requiredTables) do
        -- 验证表名合法性，防止SQL注入
        if not string.match(tableName, '^[a-zA-Z0-9_]+$') then
            print('[XD ACE] 错误: 无效的表名格式: ' .. tableName)
            table.insert(missingTables, tableName)
            goto continue
        end
        
        local success, result = pcall(function()
            return MySQL.Sync.fetchScalar('SELECT 1 FROM ' .. tableName .. ' LIMIT 1')
        end)
        
        if not success then
            table.insert(missingTables, tableName)
        end
        
        ::continue::
    end
    
    return {
        allTablesExist = #missingTables == 0,
        missingTables = missingTables
    }
end

-- 完整的数据库初始化流程
function Database.FullInit()
    print('[XD ACE] 开始数据库初始化流程...')
    
    -- 步骤1: 检查数据库连接
    if not Database.CheckConnection() then
        print('[XD ACE] ❌ 数据库连接失败，请检查MySQL配置')
        return false
    end
    
    -- 步骤2: 检查数据库是否存在
    if not Database.CheckDatabaseExists() then
        print('[XD ACE] ⚠️ 数据库不存在，尝试创建...')
        if not Database.CreateDatabase() then
            print('[XD ACE] ❌ 数据库创建失败')
            return false
        end
    end
    
    -- 步骤3: 初始化表结构
    local initResult = Database.InitTables()
    
    if not initResult.success then
        print('[XD ACE] ❌ 表初始化失败，错误:')
        for _, error in ipairs(initResult.errors) do
            print('  - ' .. error)
        end
        return false
    end
    
    -- 步骤4: 验证表结构完整性
    local verifyResult = Database.VerifyTableStructure()
    
    if not verifyResult.allTablesExist then
        print('[XD ACE] ❌ 表结构验证失败，缺失表:')
        for _, tableName in ipairs(verifyResult.missingTables) do
            print('  - ' .. tableName)
        end
        return false
    end
    
    print('[XD ACE] ✅ 数据库初始化完成，共创建/验证 ' .. initResult.tablesCreated .. ' 个表')
    return true
end

-- 数据库健康检查
function Database.HealthCheck()
    local health = {
        connection = Database.CheckConnection(),
        tables = Database.VerifyTableStructure()
    }
    
    health.overall = health.connection and health.tables.allTablesExist
    
    if Config.Debug then
        print('[XD ACE] 数据库健康检查:')
        print('  - 连接: ' .. (health.connection and '✅' or '❌'))
        print('  - 表结构: ' .. (health.tables.allTablesExist and '✅' or '❌'))
        if not health.tables.allTablesExist then
            print('  - 缺失表: ' .. table.concat(health.tables.missingTables, ', '))
        end
    end
    
    return health
end

-- 初始化数据库（带重试机制）
function Database.InitWithRetry(maxRetries, delay)
    maxRetries = maxRetries or Config.Database.maxRetries
    delay = delay or Config.Database.retryDelay
    
    for attempt = 1, maxRetries do
        print(string.format('[XD ACE] 数据库初始化尝试 %d/%d', attempt, maxRetries))
        
        if Database.FullInit() then
            return true
        end
        
        if attempt < maxRetries then
            print(string.format('[XD ACE] 等待 %d 秒后重试...', delay / 1000))
            Citizen.Wait(delay)
        end
    end
    
    print('[XD ACE] ❌ 数据库初始化失败，已达到最大重试次数')
    return false
end

-- 安全的数据库操作包装器
function Database.SafeQuery(callback, errorMessage)
    local success, result = pcall(callback)
    
    if not success then
        print('[XD ACE] 数据库错误: ' .. errorMessage)
        print('错误详情: ' .. tostring(result))
        
        -- 尝试重新连接
        if string.find(tostring(result):lower(), 'lost connection') or 
           string.find(tostring(result):lower(), 'gone away') then
            print('[XD ACE] 检测到数据库连接丢失，尝试重新初始化...')
            Database.InitWithRetry(1, 1000)
        end
        
        return nil
    end
    
    return result
end

-- 检查玩家是否被封禁
function Database.IsPlayerBanned(license, discord, ip)
    return Database.SafeQuery(function()
        local result = MySQL.Sync.fetchAll([[
            SELECT * FROM xd_ace_bans 
            WHERE (license = ? OR discord = ? OR ip = ?) 
            AND is_active = TRUE 
            AND (ban_type = 'permanent' OR unban_date > NOW())
        ]], {license, discord, ip})

        return result[1] or false
    end, "检查玩家封禁状态失败")
end

-- 兼容函数：检查玩家是否被封禁（用于server/main.lua）
function Database.CheckBan(license)
    return Database.IsPlayerBanned(license, nil, nil)
end

-- 添加封禁记录
function Database.AddBan(banData)
    local query = [[
        INSERT INTO xd_ace_bans 
        (license, discord, ip, player_name, reason, unban_date, banned_by, evidence, ban_type, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)
    ]]

    MySQL.Async.execute(query, {
        banData.license,
        banData.discord,
        banData.ip,
        banData.playerName,
        banData.reason,
        banData.unbanDate,
        banData.bannedBy,
        banData.evidence,
        banData.banType
    })
end

-- 兼容函数：添加封禁记录（用于server/main.lua，接收playerId）
function Database.AddBan(playerId, banData)
    local player = XDACE.Players[playerId]
    if not player then return end
    
    local query = [[
        INSERT INTO xd_ace_bans 
        (license, discord, ip, player_name, reason, unban_date, banned_by, evidence, ban_type, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)
    ]]
    
    local banType = banData.type == 'admin_ban' and 'permanent' or 'temporary'
    local unbanDate = banData.duration > 0 and os.date('%Y-%m-%d %H:%M:%S', os.time() + banData.duration) or nil

    MySQL.Async.execute(query, {
        player.identifier,
        '', -- discord not available
        player.ip,
        player.name,
        banData.reason,
        unbanDate,
        'XD ACE Anti-Cheat',
        '', -- evidence not available
        banType
    })
end

-- 解封玩家
function Database.UnbanPlayer(banId, adminLicense, adminName)
    MySQL.Async.execute([[
        UPDATE xd_ace_bans 
        SET is_active = FALSE 
        WHERE id = ?
    ]], {banId})

    -- 记录管理员操作
    Database.LogAdminAction(adminLicense, adminName, 'unban', nil, nil, 'Unbanned ban ID: ' .. banId)
end

-- 兼容函数：移除封禁（用于server/main.lua）
function Database.RemoveBan(license)
    MySQL.Async.execute([[
        UPDATE xd_ace_bans 
        SET is_active = FALSE 
        WHERE license = ?
    ]], {license})
    return true
end

-- 添加违规记录
function Database.AddViolation(violationData)
    local query = [[
        INSERT INTO xd_ace_violations 
        (license, player_name, violation_type, violation_data, severity)
        VALUES (?, ?, ?, ?, ?)
    ]]

    MySQL.Async.execute(query, {
        violationData.license,
        violationData.playerName,
        violationData.type,
        json.encode(violationData.data),
        violationData.severity or 'medium'
    })
end

-- 兼容函数：记录违规行为（用于server/main.lua）
function Database.LogViolation(playerId, violationData)
    local player = XDACE.Players[playerId]
    if not player then return end
    
    local query = [[
        INSERT INTO xd_ace_violations 
        (license, player_name, violation_type, violation_data, severity)
        VALUES (?, ?, ?, ?, ?)
    ]]

    MySQL.Async.execute(query, {
        player.identifier,
        player.name,
        violationData.type,
        violationData.details,
        violationData.severity or 'medium'
    })
end

-- 兼容函数：检查是否为管理员（用于server/main.lua）
function Database.IsAdmin(identifier)
    -- 检查Config中的管理员列表
    for _, adminLicense in ipairs(Config.Admins) do
        if adminLicense == identifier then
            return true
        end
    end
    
    -- 检查数据库中的管理员
    local result = MySQL.Sync.fetchScalar([[
        SELECT COUNT(*) FROM xd_ace_admins WHERE username = ?
    ]], {identifier})
    
    return result and result > 0
end

-- 获取玩家违规记录
function Database.GetPlayerViolations(license, limit)
    local result = MySQL.Sync.fetchAll([[
        SELECT * FROM xd_ace_violations 
        WHERE license = ? 
        ORDER BY timestamp DESC 
        LIMIT ?
    ]], {license, limit or 50})

    return result
end

-- 获取封禁列表
function Database.GetBanList()
    local result = MySQL.Sync.fetchAll([[
        SELECT * FROM xd_ace_bans 
        WHERE is_active = TRUE 
        ORDER BY ban_date DESC
    ]])

    return result
end

-- 更新白名单缓存
local function UpdateWhitelistCache()
    MySQL.Async.fetchAll('SELECT license FROM xd_ace_whitelist', {}, function(results)
        whitelistCache = {}
        for _, row in ipairs(results) do
            whitelistCache[row.license] = true
        end
        lastWhitelistUpdate = GetGameTimer()
    end)
end

-- 检查白名单（使用缓存）
function Database.IsWhitelisted(license)
    -- 如果缓存为空或已过期，更新缓存
    if not next(whitelistCache) or (GetGameTimer() - lastWhitelistUpdate) > WHITELIST_CACHE_INTERVAL * 1000 then
        UpdateWhitelistCache()
    end
    
    -- 检查缓存
    if whitelistCache[license] then
        return true
    end
    
    -- 缓存中未找到，进行数据库查询并更新缓存
    local result = MySQL.Sync.fetchSingle('SELECT 1 FROM xd_ace_whitelist WHERE license = ?', {license})
    local isWhitelisted = result ~= nil
    
    if isWhitelisted then
        whitelistCache[license] = true
    end
    
    return isWhitelisted
end

-- 添加白名单
function Database.AddToWhitelist(license, discord, playerName, adminName, notes)
    MySQL.Async.execute([[
        INSERT INTO xd_ace_whitelist 
        (license, discord, player_name, added_by, notes)
        VALUES (?, ?, ?, ?, ?)
    ]], {license, discord, playerName, adminName, notes}, function(affectedRows)
        if affectedRows > 0 then
            whitelistCache[license] = true -- 更新缓存
        end
    end)
end

-- 移除白名单
function Database.RemoveFromWhitelist(license)
    MySQL.Async.execute([[
        DELETE FROM xd_ace_whitelist 
        WHERE license = ?
    ]], {license}, function(affectedRows)
        if affectedRows > 0 then
            whitelistCache[license] = nil -- 更新缓存
        end
    end)
end

-- 记录管理员操作
function Database.LogAdminAction(adminLicense, adminName, action, targetLicense, targetName, details)
    MySQL.Async.execute([[
        INSERT INTO xd_ace_admin_logs 
        (admin_license, admin_name, action, target_license, target_name, details)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {adminLicense, adminName, action, targetLicense, targetName, details})
end

-- 初始化数据库
CreateThread(function()
    if Config.Database.autoInitialize then
        Database.InitWithRetry()
    else
        print('[XD ACE] 数据库自动初始化已禁用')
    end
end)

-- 定期进行数据库健康检查
CreateThread(function()
    while true do
        Citizen.Wait(Config.Database.healthCheckInterval)
        Database.HealthCheck()
    end
end)