-- XD ACE Godmode Detection Module

local module = {
    Name = "godmode",
    Enabled = true,
    Description = "Detects players with godmode (invincibility)",
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
            godmodeViolationCount = 0,
            lastHealth = GetEntityHealth(ped),
            lastArmor = GetPedArmour(ped),
            damageReceived = 0
        }
    end
    
    local currentHealth = GetEntityHealth(ped)
    local currentArmor = GetPedArmour(ped)
    
    -- Check 1: Godmode flag detection
    if not IsEntityInvincible(ped) and not IsPedGod(ped) then
        -- Check 2: Health never decreases despite taking damage
        local isTakingDamage = IsEntityPlayingAnim(ped, "reaction@shot@front", "react_to_shot_front", 3) or 
                               IsEntityPlayingAnim(ped, "reaction@shot@back", "react_to_shot_back", 3) or
                               IsEntityPlayingAnim(ped, "reaction@shot@left", "react_to_shot_left", 3) or
                               IsEntityPlayingAnim(ped, "reaction@shot@right", "react_to_shot_right", 3)
        
        if isTakingDamage then
            playerData.data.damageReceived = playerData.data.damageReceived + 1
            
            -- If taking damage but health doesn't decrease after multiple hits
            if playerData.data.damageReceived >= 3 then
                if currentHealth == playerData.data.lastHealth and currentArmor == playerData.data.lastArmor then
                    playerData.data.godmodeViolationCount = playerData.data.godmodeViolationCount + 1
                    
                    if playerData.data.godmodeViolationCount >= 2 then
                        result.detected = true
                        result.type = "godmode"
                        result.description = "Godmode Detected - Health Never Decreases"
                        result.details = {
                            health = currentHealth,
                            armor = currentArmor,
                            damageReceived = playerData.data.damageReceived,
                            violationCount = playerData.data.godmodeViolationCount
                        }
                        result.severity = 3
                        return result
                    end
                else
                    -- Reset counter if health actually decreases
                    playerData.data.damageReceived = 0
                end
            end
        end
        
        -- Check 3: Health exceeds maximum allowed
        local maxHealth = GetEntityMaxHealth(ped)
        if currentHealth > maxHealth or currentHealth <= 0 then
            result.detected = true
            result.type = "godmode"
            result.description = "Invalid Health Value Detected"
            result.details = {
                health = currentHealth,
                maxHealth = maxHealth,
                armor = currentArmor
            }
            result.severity = 3
            return result
        end
        
        -- Check 4: Armor exceeds maximum allowed (default max is 100)
        if currentArmor > 100 then
            result.detected = true
            result.type = "godmode"
            result.description = "Invalid Armor Value Detected"
            result.details = {
                armor = currentArmor,
                health = currentHealth
            }
            result.severity = 3
            return result
        end
        
        -- Check 5: Rapid health regeneration (unrealistic)
        if playerData.data.lastHealth then
            local healthDiff = currentHealth - playerData.data.lastHealth
            if healthDiff > 20 and not IsPedInAnyVehicle(ped, false) then
                -- More than 20 health regenerated in a short time (not in vehicle)
                result.detected = true
                result.type = "godmode"
                result.description = "Rapid Health Regeneration Detected"
                result.details = {
                    healthDiff = healthDiff,
                    previousHealth = playerData.data.lastHealth,
                    currentHealth = currentHealth,
                    inVehicle = IsPedInAnyVehicle(ped, false)
                }
                result.severity = 2
                return result
            end
        end
        
        -- Update last health and armor values
        playerData.data.lastHealth = currentHealth
        playerData.data.lastArmor = currentArmor
    else
        -- Direct godmode flag detected
        result.detected = true
        result.type = "godmode"
        result.description = "Godmode Flag Detected"
        result.details = {
            isInvincible = IsEntityInvincible(ped),
            isPedGod = IsPedGod(ped),
            health = currentHealth,
            armor = currentArmor
        }
        result.severity = 3
        return result
    end
    
    return result
end

return module