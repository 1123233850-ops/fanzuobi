-- XD ACE Super Jump Detection Module

local module = {
    Name = "superjump",
    Enabled = true,
    Description = "Detects unrealistic jump heights and velocities",
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
            lastPosition = nil,
            lastVelocity = nil,
            jumpCount = 0,
            suspiciousJumpCount = 0,
            lastJumpTime = 0,
            inAir = false
        }
    end
    
    -- Check if player is on ground
    local isOnGround = IsPedOnGround(ped)
    local isInAir = IsPedJumping(ped) or not isOnGround
    
    local data = playerData.data
    local currentPosition = GetEntityCoords(ped)
    local currentVelocity = GetEntityVelocity(ped)
    local currentTime = GetGameTimer()
    
    -- Detect super jump height
    if isOnGround and data.inAir then
        -- Player landed, calculate jump height
        if data.lastPosition then
            local jumpHeight = math.abs(currentPosition.z - data.lastPosition.z)
            
            -- Normal jump height is about 1.5-2.5 meters, set threshold to 3.5 meters
            if jumpHeight > 3.5 then
                data.suspiciousJumpCount = data.suspiciousJumpCount + 1
                
                -- Check if consecutive super jumps detected
                if data.suspiciousJumpCount >= 3 then
                    result.detected = true
                    result.reason = "超级跳跃作弊检测 - 跳跃高度异常: " .. string.format("%.2f", jumpHeight) .. "米"
                    result.action = "kick"
                    return result
                end
            else
                -- Normal jump, reset suspicious count
                data.suspiciousJumpCount = math.max(0, data.suspiciousJumpCount - 1)
            end
        end
        
        data.inAir = false
    elseif isInAir and not data.inAir then
        -- Player jumped, record jump position
        data.lastPosition = currentPosition
        data.inAir = true
        data.jumpCount = data.jumpCount + 1
    end
    
    -- Detect abnormal vertical velocity
    local verticalVelocity = math.abs(currentVelocity.z)
    if verticalVelocity > 30.0 then
        data.suspiciousJumpCount = data.suspiciousJumpCount + 2
        
        if data.suspiciousJumpCount >= 5 then
            result.detected = true
            result.reason = "超级跳跃作弊检测 - 垂直速度异常: " .. string.format("%.2f", verticalVelocity) .. "m/s"
            result.action = "kick"
            return result
        end
    end
    
    return result
end

return module