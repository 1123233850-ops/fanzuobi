-- 无敌模式检测模块

XDACE.Detections.godmode = {
    Name = "Godmode",
    Enabled = Config.Detection.Godmode.Enabled,
    CheckInterval = Config.Detection.Godmode.CheckInterval,
    Severity = Config.Detection.Godmode.Severity,
    Parameters = Config.Detection.Godmode.Parameters,
    LastCheck = 0,
    damageImmunityCount = 0
}

function XDACE.Detections.godmode.Check()
    local currentTime = GetGameTimer()
    if currentTime - XDACE.Detections.godmode.LastCheck < XDACE.Detections.godmode.CheckInterval then
        return false
    end
    XDACE.Detections.godmode.LastCheck = currentTime
    
    local playerPed = PlayerPedId()
    
    -- 获取当前健康值和护甲值
    local health = GetEntityHealth(playerPed)
    local armor = GetPedArmour(playerPed)
    
    -- 记录健康和护甲值
    local lastHealth = XDACE.Player.lastHealth or health
    local lastArmor = XDACE.Player.lastArmor or armor
    
    XDACE.Player.lastHealth = health
    XDACE.Player.lastArmor = armor
    
    -- 检测无敌模式
    local violation = false
    local reason = ""
    
    -- 检查健康值和护甲值是否超过正常范围
    if health > XDACE.Detections.godmode.Parameters.HealthThreshold then
        violation = true
        reason = string.format("健康值异常 - 当前值: %d, 正常最大值: 100", health)
    elseif armor > XDACE.Detections.godmode.Parameters.ArmorThreshold then
        violation = true
        reason = string.format("护甲值异常 - 当前值: %d, 正常最大值: 100", armor)
    end
    
    -- 检查是否免疫伤害
    if not violation and lastHealth > health then
        -- 玩家受到了伤害，重置免疫计数
        XDACE.Detections.godmode.damageImmunityCount = 0
    elseif not violation and lastHealth == health then
        -- 玩家没有受到伤害，增加免疫计数
        XDACE.Detections.godmode.damageImmunityCount = XDACE.Detections.godmode.damageImmunityCount + 1
        
        -- 检查连续免疫伤害次数
        if XDACE.Detections.godmode.damageImmunityCount > XDACE.Detections.godmode.Parameters.DamageImmunityThreshold then
            violation = true
            reason = string.format("连续免疫伤害 - 次数: %d", XDACE.Detections.godmode.damageImmunityCount)
        end
    end
    
    if violation then
        return {
            type = "godmode",
            reason = reason,
            severity = XDACE.Detections.godmode.Severity,
            data = {
                health = health,
                armor = armor,
                damageImmunityCount = XDACE.Detections.godmode.damageImmunityCount
            }
        }
    end
    
    return false
end