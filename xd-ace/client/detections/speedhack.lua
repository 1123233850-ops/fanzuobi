-- 速度hack检测模块

XDACE.Detections.speedhack = {
    Name = "Speedhack",
    Enabled = Config.Detection.Speedhack.Enabled,
    CheckInterval = Config.Detection.Speedhack.CheckInterval,
    Severity = Config.Detection.Speedhack.Severity,
    Parameters = Config.Detection.Speedhack.Parameters,
    LastCheck = 0
}

function XDACE.Detections.speedhack.Check()
    local currentTime = GetGameTimer()
    if currentTime - XDACE.Detections.speedhack.LastCheck < XDACE.Detections.speedhack.CheckInterval then
        return false
    end
    XDACE.Detections.speedhack.LastCheck = currentTime
    
    local playerPed = PlayerPedId()
    local isInVehicle = IsPedInAnyVehicle(playerPed, false)
    
    -- 获取当前速度
    local velocity = GetEntityVelocity(playerPed)
    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
    
    -- 根据移动状态检查速度
    local maxAllowedSpeed = 0
    
    if isInVehicle then
        -- 车辆速度（转换为km/h）
        speed = speed * 3.6
        maxAllowedSpeed = XDACE.Detections.speedhack.Parameters.MaxInVehicleSpeed * XDACE.Detections.speedhack.Parameters.SpeedTolerance
    else
        -- 步行速度（m/s）
        maxAllowedSpeed = XDACE.Detections.speedhack.Parameters.MaxOnFootSpeed * XDACE.Detections.speedhack.Parameters.SpeedTolerance
        
        -- 检查游泳速度
        if IsPedSwimming(playerPed) then
            maxAllowedSpeed = XDACE.Detections.speedhack.Parameters.MaxSwimSpeed * XDACE.Detections.speedhack.Parameters.SpeedTolerance
        end
    end
    
    -- 记录当前速度
    XDACE.Player.movementData.speed = speed
    
    -- 检测速度hack
    if speed > maxAllowedSpeed then
        return {
            type = "speedhack",
            reason = string.format("速度异常 - 当前速度: %.2f, 最大允许速度: %.2f", speed, maxAllowedSpeed),
            severity = XDACE.Detections.speedhack.Severity,
            data = {
                speed = speed,
                maxAllowedSpeed = maxAllowedSpeed,
                isInVehicle = isInVehicle
            }
        }
    end
    
    return false
end