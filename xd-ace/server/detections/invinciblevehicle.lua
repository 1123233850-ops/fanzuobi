-- XD ACE Invincible Vehicle Detection Module

local module = {
    Name = "invinciblevehicle",
    Enabled = true,
    Description = "Detects vehicles with invincible properties",
    Severity = 3
}

function module.Check(playerId, playerData)
    local result = { detected = false }
    
    if not playerData then return result end
    
    local ped = GetPlayerPed(playerId)
    if not ped or not DoesEntityExist(ped) then return result end
    
    -- Check if player is in a vehicle
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        -- Player is not in a vehicle, reset data
        if playerData.data then
            playerData.data.lastVehicle = nil
            playerData.data.lastHealth = 0
            playerData.data.consecutiveSameHealth = 0
        end
        return result
    end
    
    -- Initialize player data if not exists
    if not playerData.data then
        playerData.data = {
            lastVehicle = nil,
            lastHealth = 0,
            consecutiveSameHealth = 0,
            suspiciousCount = 0,
            lastCheckTime = GetGameTimer()
        }
    end
    
    local data = playerData.data
    local currentHealth = GetVehicleEngineHealth(vehicle)
    local currentBodyHealth = GetVehicleBodyHealth(vehicle)
    local currentTime = GetGameTimer()
    
    -- Check if vehicle has changed
    if data.lastVehicle ~= vehicle then
        data.lastVehicle = vehicle
        data.lastHealth = currentHealth
        data.consecutiveSameHealth = 0
        data.lastCheckTime = currentTime
        return result
    end
    
    -- Calculate time difference
    local timeDiff = currentTime - data.lastCheckTime
    
    -- Only check after a certain interval
    if timeDiff < 1500 then return result end
    
    -- Check for abnormal vehicle health
    if currentHealth > 1000.0 or currentBodyHealth > 1000.0 then
        result.detected = true
        result.reason = "无敌载具作弊检测 - 载具健康值异常: 引擎" .. string.format("%.0f", currentHealth) .. "/车身" .. string.format("%.0f", currentBodyHealth)
        result.action = "kick"
        return result
    end
    
    -- Check if vehicle health remains unchanged despite damage
    if currentHealth == data.lastHealth and currentHealth < 1000.0 then
        -- Health is the same, increase consecutive count
        data.consecutiveSameHealth = data.consecutiveSameHealth + 1
        
        -- Check if consecutive same health count is too high
        if data.consecutiveSameHealth >= 4 then
            data.suspiciousCount = data.suspiciousCount + 1
            
            -- If suspicious count reaches threshold, mark as detected
            if data.suspiciousCount >= 3 then
                result.detected = true
                result.reason = "无敌载具作弊检测 - 载具健康值长时间不变"
                result.action = "kick"
                return result
            end
        end
    else
        -- Health changed, reset count
        data.consecutiveSameHealth = 0
        data.lastHealth = currentHealth
    end
    
    -- Detect invincible vehicle flag
    if IsVehicleInvincible(vehicle) then
        result.detected = true
        result.reason = "无敌载具作弊检测 - 检测到载具无敌标志"
        result.action = "kick"
        return result
    end
    
    -- Update last check time
    data.lastCheckTime = currentTime
    
    return result
end

return module