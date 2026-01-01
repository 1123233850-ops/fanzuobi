-- XD ACE Aimbot Detection Module

local module = {
    Name = "aimbot",
    Enabled = true,
    Description = "Detects suspicious aiming patterns",
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
            perfectShots = 0,
            suspiciousAimCount = 0,
            lastAim = nil,
            aimStability = 0,
            headshotCount = 0,
            totalShotCount = 0
        }
    end
    
    -- Check if player is aiming
    if IsPlayerFreeAiming(playerId) then
        local aimCoords = GetGameplayCamCoord(playerId)
        local aimRotation = GetGameplayCamRot(playerId, 2)
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
                
                -- Check for headshot only pattern
                local headBoneIndex = GetEntityBoneIndexByName(targetPed, "HEAD")
                local headCoords = GetWorldPositionOfEntityBone(targetPed, headBoneIndex)
                local headDistance = #(hitCoords - headCoords)
                
                if headDistance < 0.5 then
                    playerData.data.headshotCount = playerData.data.headshotCount + 1
                end
                playerData.data.totalShotCount = playerData.data.totalShotCount + 1
                
                -- Check for suspicious headshot ratio (90%+ headshots)
                if playerData.data.totalShotCount >= 10 then
                    local headshotRatio = playerData.data.headshotCount / playerData.data.totalShotCount
                    if headshotRatio > 0.9 then
                        result.detected = true
                        result.type = "aimbot"
                        result.description = "Suspicious Headshot Ratio Detected"
                        result.details = {
                            headshotRatio = headshotRatio,
                            headshots = playerData.data.headshotCount,
                            totalShots = playerData.data.totalShotCount,
                            distance = distance
                        }
                        result.severity = 3
                        return result
                    end
                end
                
                -- Check for perfect aim accuracy
                if math.abs(hitDistance - targetDistance) < 0.3 then
                    -- Track consecutive perfect shots
                    playerData.data.perfectShots = playerData.data.perfectShots + 1
                    
                    -- If 5+ consecutive perfect shots, flag as aimbot
                    if playerData.data.perfectShots >= 5 then
                        result.detected = true
                        result.type = "aimbot"
                        result.description = "Perfect Aim Accuracy Detected"
                        result.details = {
                            consecutivePerfectShots = playerData.data.perfectShots,
                            hitDistance = hitDistance,
                            targetDistance = targetDistance,
                            aimCoords = aimCoords,
                            targetCoords = targetCoords,
                            distance = distance
                        }
                        result.severity = 3
                        return result
                    end
                else
                    -- Reset counter if not perfect shot
                    playerData.data.perfectShots = 0
                end
            end
            
            -- Check for instant lock-on (suspiciously fast aiming)
            if playerData.data.lastAim then
                local lastAim = playerData.data.lastAim
                local timeDiff = GetGameTimer() - lastAim.timestamp
                local lastTarget = lastAim.target
                
                if lastTarget ~= targetPed then
                    -- New target acquired
                    if timeDiff < 150 then -- Less than 150ms to switch targets
                        playerData.data.suspiciousAimCount = playerData.data.suspiciousAimCount + 1
                        
                        -- If multiple suspicious aim events, flag as aimbot
                        if playerData.data.suspiciousAimCount >= 3 then
                            result.detected = true
                            result.type = "aimbot"
                            result.description = "Rapid Target Switching Detected"
                            result.details = {
                                timeToSwitch = timeDiff,
                                distance = distance,
                                suspiciousAimCount = playerData.data.suspiciousAimCount,
                                previousTarget = lastTarget,
                                newTarget = targetPed
                            }
                            result.severity = 3
                            return result
                        end
                    end
                end
            end
            
            -- Check for aim stability (no natural wobble)
            if playerData.data.lastAim and playerData.data.lastAim.rotation then
                local rotDiff = {
                    x = math.abs(aimRotation.x - playerData.data.lastAim.rotation.x),
                    y = math.abs(aimRotation.y - playerData.data.lastAim.rotation.y),
                    z = math.abs(aimRotation.z - playerData.data.lastAim.rotation.z)
                }
                
                local totalRotDiff = rotDiff.x + rotDiff.y + rotDiff.z
                
                if totalRotDiff < 0.1 then -- Almost no rotation change (perfect stability)
                    playerData.data.aimStability = playerData.data.aimStability + 1
                    
                    if playerData.data.aimStability >= 10 then
                        result.detected = true
                        result.type = "aimbot"
                        result.description = "Unnatural Aim Stability Detected"
                        result.details = {
                            totalRotDiff = totalRotDiff,
                            stabilityCount = playerData.data.aimStability,
                            rotation = aimRotation,
                            distance = distance
                        }
                        result.severity = 2
                        return result
                    end
                else
                    playerData.data.aimStability = 0
                end
            end
            
            -- Update aim info
            playerData.data.lastAim = {
                timestamp = GetGameTimer(),
                target = targetPed,
                coords = aimCoords,
                rotation = aimRotation
            }
        end
    else
        -- Reset counters when not aiming
        playerData.data.perfectShots = 0
        playerData.data.aimStability = 0
    end
    
    return result
end

return module
