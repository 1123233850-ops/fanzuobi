-- XD ACE Speedhack Detection Module

local module = {
    Name = "speedhack",
    Enabled = true,
    Description = "Detects unrealistic movement speeds",
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
            lastCheck = nil,
            speedViolationCount = 0,
            teleportCount = 0,
            lastTeleport = nil
        }
    end
    
    local currentCoords = GetEntityCoords(ped)
    local currentTime = GetGameTimer() -- Use game timer for more accurate measurements
    
    -- Check if we have previous data
    if playerData.data.lastCheck then
        local lastCoords = playerData.data.lastCheck.coords
        local lastTime = playerData.data.lastCheck.time
        local timeDiff = currentTime - lastTime
        
        if timeDiff > 0 and timeDiff < 2000 then -- Only check if time difference is reasonable (2 seconds max)
            local distance = #(currentCoords - lastCoords)
            local speed = (distance / timeDiff) * 3.6 * 1000 -- Convert to km/h
            
            local maxAllowedSpeed = 100.0 -- Default max speed (km/h)
            
            -- Adjust max speed based on player state
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local vehicleClass = GetVehicleClass(vehicle)
                local vehicleMaxSpeed = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel") or 100.0
                
                -- Different max speeds for different vehicle classes, plus a buffer
                if vehicleClass == 15 then -- Super cars
                    maxAllowedSpeed = vehicleMaxSpeed * 3.6 * 1.3 -- 30% buffer
                elseif vehicleClass == 14 then -- Sports cars
                    maxAllowedSpeed = vehicleMaxSpeed * 3.6 * 1.3
                elseif vehicleClass == 7 then -- Muscle cars
                    maxAllowedSpeed = vehicleMaxSpeed * 3.6 * 1.35
                else
                    maxAllowedSpeed = vehicleMaxSpeed * 3.6 * 1.4
                end
            else
                -- On foot
                if IsPedSprinting(ped) then
                    maxAllowedSpeed = 50.0 -- Sprinting max speed
                elseif IsPedRunning(ped) then
                    maxAllowedSpeed = 35.0 -- Running max speed
                elseif IsPedWalking(ped) then
                    maxAllowedSpeed = 15.0 -- Walking max speed
                else
                    maxAllowedSpeed = 5.0 -- Idle/standing max speed
                end
            end
            
            -- Check for teleportation (extreme distance in short time)
            if distance > 100.0 and timeDiff < 500 then -- More than 100 meters in 0.5 seconds
                playerData.data.teleportCount = playerData.data.teleportCount + 1
                
                -- Check for multiple teleport attempts
                if playerData.data.teleportCount >= 2 then
                    result.detected = true
                    result.type = "speedhack"
                    result.description = "Teleportation Detected"
                    result.details = {
                        distance = distance,
                        timeDiff = timeDiff,
                        fromCoords = lastCoords,
                        toCoords = currentCoords,
                        teleportCount = playerData.data.teleportCount
                    }
                    result.severity = 3
                    return result
                end
                
                playerData.data.lastTeleport = currentTime
            end
            
            -- Check if speed exceeds allowed limit
            if speed > maxAllowedSpeed * 1.3 then -- 30% over limit for more accurate detection
                playerData.data.speedViolationCount = playerData.data.speedViolationCount + 1
                
                -- Multiple speed violations in a row increase severity
                if playerData.data.speedViolationCount >= 2 then
                    result.detected = true
                    result.type = "speedhack"
                    result.description = "Unrealistic Movement Speed Detected"
                    result.details = {
                        speed = speed,
                        maxAllowed = maxAllowedSpeed,
                        distance = distance,
                        timeDiff = timeDiff,
                        speedViolationCount = playerData.data.speedViolationCount,
                        inVehicle = IsPedInAnyVehicle(ped, false),
                        coords = currentCoords
                    }
                    result.severity = 3
                    return result
                end
            else
                -- Reset violation counters if speed is normal
                playerData.data.speedViolationCount = 0
            end
        end
    end
    
    -- Update last check data
    playerData.data.lastCheck = {
        coords = currentCoords,
        time = currentTime
    }
    
    return result
end

return module
