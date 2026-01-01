-- XD ACE Client Aimbot Detection Module

local module = {
    Name = "aimbot",
    Enabled = true,
    Description = "Detects suspicious aiming patterns on client side",
    Severity = 3
}

local lastAimInfo = nil
local perfectShotCount = 0
local aimStartTime = 0

function module.Check()
    local result = { detected = false }
    
    local playerId = PlayerId()
    local ped = PlayerPedId()
    
    -- Check if player is aiming
    if IsPlayerFreeAiming(playerId) then
        local currentTime = GetGameTimer()
        local aimCoords = GetGameplayCamCoord()
        local aimRotation = GetGameplayCamRot(2)
        local targetPed = GetPlayerTargetEntity(playerId)
        
        if targetPed and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(aimCoords - targetCoords)
            
            -- Calculate aim direction
            local aimDirection = vector3(
                -math.sin(aimRotation.z) * math.abs(math.cos(aimRotation.x)),
                math.cos(aimRotation.z) * math.abs(math.cos(aimRotation.x)),
                math.sin(aimRotation.x)
            )
            
            -- Raycast to check accuracy
            local hit, hitCoords = GetShapeTestResult(StartShapeTestRay(aimCoords, aimCoords + aimDirection * 1000, -1, ped, 0))
            
            if hit == 1 then
                local hitDistance = #(aimCoords - hitCoords)
                local targetDistance = #(aimCoords - targetCoords)
                
                -- Check for perfect aim accuracy
                if math.abs(hitDistance - targetDistance) < 0.3 then
                    perfectShotCount = perfectShotCount + 1
                    
                    if perfectShotCount >= 5 then
                        result.detected = true
                        result.type = "aimbot"
                        result.description = "Perfect Aim Accuracy Detected (Client)"
                        result.details = {
                            consecutivePerfectShots = perfectShotCount,
                            hitDistance = hitDistance,
                            targetDistance = targetDistance,
                            distance = distance
                        }
                        result.severity = 3
                        perfectShotCount = 0 -- Reset after detection
                        return result
                    end
                else
                    perfectShotCount = 0 -- Reset if not perfect
                end
            end
            
            -- Check for instant lock-on
            if lastAimInfo then
                local timeDiff = currentTime - lastAimInfo.time
                local lastTarget = lastAimInfo.target
                
                if lastTarget ~= targetPed then
                    -- New target acquired
                    if timeDiff < 150 then -- Less than 150ms to switch targets
                        result.detected = true
                        result.type = "aimbot"
                        result.description = "Instant Target Switch Detected"
                        result.details = {
                            timeToSwitch = timeDiff,
                            distance = distance,
                            previousTarget = lastTarget,
                            newTarget = targetPed
                        }
                        result.severity = 3
                        return result
                    end
                end
            end
            
            -- Update aim info
            lastAimInfo = {
                time = currentTime,
                target = targetPed,
                coords = aimCoords
            }
        end
    else
        -- Reset when not aiming
        perfectShotCount = 0
        lastAimInfo = nil
    end
    
    return result
end

return module
