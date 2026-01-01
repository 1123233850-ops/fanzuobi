-- XD ACE Wallhack Detection Module

local module = {
    Name = "wallhack",
    Enabled = true,
    Description = "Detects players with wallhack (seeing through walls)",
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
            wallhackViolationCount = 0,
            lastAimTarget = nil,
            suspiciousTargetChanges = 0,
            lastLineOfSightCheck = nil
        }
    end
    
    -- Check if player is aiming
    if IsPlayerFreeAiming(playerId) then
        local aimCoords = GetGameplayCamCoord(playerId)
        local targetPed = GetPlayerTargetEntity(playerId)
        
        if targetPed and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            
            -- Check 1: Line of sight violation
            -- Cast a ray to check if there's an obstruction between the player and target
            local hit, _, _, _, entityHit = GetShapeTestResult(StartShapeTestRay(aimCoords, targetCoords, 1, ped, 0))
            
            if hit == 1 then
                -- Ray hit something
                if entityHit ~= targetPed then
                    -- Ray hit something other than the target, meaning there's an obstruction
                    -- Check if the player is still looking at the target
                    local isLookingAtTarget = IsEntityLookingAtEntity(ped, targetPed, 30.0) -- 30 degree field of view
                    
                    if isLookingAtTarget then
                        playerData.data.wallhackViolationCount = playerData.data.wallhackViolationCount + 1
                        
                        if playerData.data.wallhackViolationCount >= 3 then
                            result.detected = true
                            result.type = "wallhack"
                            result.description = "Wallhack Detected - Seeing Through Obstructions"
                            result.details = {
                                obstruction = GetEntityModel(entityHit),
                                distance = #(aimCoords - targetCoords),
                                violationCount = playerData.data.wallhackViolationCount
                            }
                            result.severity = 3
                            return result
                        end
                    end
                end
            end
            
            -- Check 2: Targeting through solid objects
            local targetPed = GetPlayerTargetEntity(playerId)
            local playerCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - targetCoords)
            
            -- Create a raycast from player to target
            local handle = StartShapeTestRay(playerCoords, targetCoords, 1, ped, 0)
            local _, hit, hitCoords, _, hitEntity = GetShapeTestResult(handle)
            
            if hit == 1 and hitEntity ~= targetPed then
                -- Ray hit something other than the target
                local hitDistance = #(playerCoords - hitCoords)
                if hitDistance < distance then
                    -- There's an object between player and target
                    playerData.data.suspiciousTargetChanges = playerData.data.suspiciousTargetChanges + 1
                    
                    if playerData.data.suspiciousTargetChanges >= 2 then
                        result.detected = true
                        result.type = "wallhack"
                        result.description = "Wallhack Detected - Targeting Through Objects"
                        result.details = {
                            objectBetween = GetEntityModel(hitEntity),
                            playerToObjectDistance = hitDistance,
                            playerToTargetDistance = distance,
                            suspiciousChanges = playerData.data.suspiciousTargetChanges
                        }
                        result.severity = 3
                        return result
                    end
                end
            end
            
            -- Check 3: Unnatural target acquisition sequence
            if playerData.data.lastAimTarget and playerData.data.lastAimTarget ~= targetPed then
                local lastTargetCoords = GetEntityCoords(playerData.data.lastAimTarget)
                local angleChange = math.acos(
                    (targetCoords.x - playerCoords.x) * (lastTargetCoords.x - playerCoords.x) +
                    (targetCoords.y - playerCoords.y) * (lastTargetCoords.y - playerCoords.y) /
                    (#(targetCoords - playerCoords) * #(lastTargetCoords - playerCoords))
                ) * (180 / math.pi)
                
                -- Check if player changed target through a large angle instantly
                if angleChange > 90 then -- More than 90 degree turn
                    if playerData.data.lastLineOfSightCheck then
                        local timeDiff = GetGameTimer() - playerData.data.lastLineOfSightCheck
                        if timeDiff < 200 then -- Less than 200ms to change target
                            result.detected = true
                            result.type = "wallhack"
                            result.description = "Wallhack Detected - Unnatural Target Switching"
                            result.details = {
                                angleChange = angleChange,
                                timeToSwitch = timeDiff,
                                previousTarget = GetEntityModel(playerData.data.lastAimTarget),
                                newTarget = GetEntityModel(targetPed)
                            }
                            result.severity = 3
                            return result
                        end
                    end
                end
            end
            
            -- Update last aim target
            playerData.data.lastAimTarget = targetPed
            playerData.data.lastLineOfSightCheck = GetGameTimer()
        end
    end
    
    return result
end

return module