-- XD ACE Infinite Ammo Detection Module

local module = {
    Name = "infiniteammo",
    Enabled = true,
    Description = "Detects players with infinite ammo",
    Severity = 3
}

function module.Check(playerId, playerData)
    local result = { detected = false }
    
    if not playerData then return result end
    
    local ped = GetPlayerPed(playerId)
    if not ped or not DoesEntityExist(ped) then return result end
    
    -- Initialize player data if not exists
    if not playerData.data then
        playerData.data = {
            lastAmmoCount = {},
            consecutiveSameAmmo = {},
            suspiciousCount = 0,
            lastCheckTime = GetGameTimer()
        }
    end
    
    local weapon = GetSelectedPedWeapon(ped)
    
    -- Skip invalid weapons
    if weapon == 0 or weapon == 4294967295 then return result end
    
    local data = playerData.data
    local currentAmmo = GetAmmoInPedWeapon(ped, weapon)
    local currentTime = GetGameTimer()
    
    -- Check if weapon is in records
    if not data.lastAmmoCount[weapon] then
        data.lastAmmoCount[weapon] = currentAmmo
        data.consecutiveSameAmmo[weapon] = 0
        data.lastCheckTime = currentTime
        return result
    end
    
    -- Calculate time difference
    local timeDiff = currentTime - data.lastCheckTime
    
    -- Only check after a certain interval
    if timeDiff < 1000 then return result end
    
    -- Check if ammo count is suspiciously the same
    if currentAmmo == data.lastAmmoCount[weapon] then
        -- Ammo count is the same, increase consecutive count
        data.consecutiveSameAmmo[weapon] = data.consecutiveSameAmmo[weapon] + 1
        
        -- Check if consecutive same ammo count is too high
        if data.consecutiveSameAmmo[weapon] >= 5 then
            data.suspiciousCount = data.suspiciousCount + 1
            
            -- If suspicious count reaches threshold, mark as detected
            if data.suspiciousCount >= 3 then
                result.detected = true
                result.reason = "无限弹药作弊检测 - 连续射击但弹药数量不变"
                result.action = "kick"
                return result
            end
        end
    else
        -- Ammo count changed, reset suspicious counts
        data.consecutiveSameAmmo[weapon] = 0
        data.lastAmmoCount[weapon] = currentAmmo
        data.suspiciousCount = math.max(0, data.suspiciousCount - 1)
    end
    
    -- Update last check time
    data.lastCheckTime = currentTime
    
    return result
end

return module