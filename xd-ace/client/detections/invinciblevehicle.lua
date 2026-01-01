-- 无敌车辆检测模块

XDACE.Detections.invinciblevehicle = {
    Name = "InvincibleVehicle",
    Enabled = Config.Detection.InvincibleVehicle.Enabled,
    CheckInterval = Config.Detection.InvincibleVehicle.CheckInterval,
    Severity = Config.Detection.InvincibleVehicle.Severity,
    Parameters = Config.Detection.InvincibleVehicle.Parameters,
    LastCheck = 0,
    damageImmunityCount = 0
}

function XDACE.Detections.invinciblevehicle.Check()
    local currentTime = GetGameTimer()
    if currentTime - XDACE.Detections.invinciblevehicle.LastCheck < XDACE.Detections.invinciblevehicle.CheckInterval then
        return false
    end
    XDACE.Detections.invinciblevehicle.LastCheck = currentTime
    
    local playerPed = PlayerPedId()
    
    -- 检查玩家是否在车内
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        -- 获取车辆健康值
        local health = GetVehicleEngineHealth(vehicle)
        local bodyHealth = GetVehicleBodyHealth(vehicle)
        
        -- 记录车辆健康值
        local lastVehicle = XDACE.Player.vehicleData.lastVehicle
        local lastHealth = XDACE.Player.vehicleData.lastHealth or health
        
        XDACE.Player.vehicleData.lastVehicle = vehicle
        XDACE.Player.vehicleData.lastHealth = health
        
        -- 检测无敌车辆
        local violation = false
        local reason = ""
        
        -- 检查车辆健康值是否超过正常范围
        if health > XDACE.Detections.invinciblevehicle.Parameters.MaxVehicleHealth then
            violation = true
            reason = string.format("车辆健康值异常 - 当前引擎健康: %.2f, 正常最大值: 1000", health)
        elseif bodyHealth > XDACE.Detections.invinciblevehicle.Parameters.MaxVehicleHealth then
            violation = true
            reason = string.format("车辆健康值异常 - 当前车身健康: %.2f, 正常最大值: 1000", bodyHealth)
        end
        
        -- 检查是否免疫伤害
        if not violation and lastVehicle == vehicle and lastHealth > health then
            -- 车辆受到了伤害，重置免疫计数
            XDACE.Detections.invinciblevehicle.damageImmunityCount = 0
        elseif not violation and lastVehicle == vehicle and lastHealth == health then
            -- 车辆没有受到伤害，增加免疫计数
            XDACE.Detections.invinciblevehicle.damageImmunityCount = XDACE.Detections.invinciblevehicle.damageImmunityCount + 1
            
            -- 检查连续免疫伤害次数
            if XDACE.Detections.invinciblevehicle.damageImmunityCount > XDACE.Detections.invinciblevehicle.Parameters.DamageImmunityThreshold then
                violation = true
                reason = string.format("车辆连续免疫伤害 - 次数: %d", XDACE.Detections.invinciblevehicle.damageImmunityCount)
            end
        end
        
        if violation then
            return {
                type = "invinciblevehicle",
                reason = reason,
                severity = XDACE.Detections.invinciblevehicle.Severity,
                data = {
                    vehicleHealth = health,
                    bodyHealth = bodyHealth,
                    damageImmunityCount = XDACE.Detections.invinciblevehicle.damageImmunityCount
                }
            }
        end
    end
    
    return false
end