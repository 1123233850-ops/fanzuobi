-- 穿墙透视检测模块

XDACE.Detections.wallhack = {
    Name = "Wallhack",
    Enabled = Config.Detection.Wallhack.Enabled,
    CheckInterval = Config.Detection.Wallhack.CheckInterval,
    Severity = Config.Detection.Wallhack.Severity,
    Parameters = Config.Detection.Wallhack.Parameters,
    LastCheck = 0
}

function XDACE.Detections.wallhack.Check()
    local currentTime = GetGameTimer()
    if currentTime - XDACE.Detections.wallhack.LastCheck < XDACE.Detections.wallhack.CheckInterval then
        return false
    end
    XDACE.Detections.wallhack.LastCheck = currentTime
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- 检测穿墙透视
    local visibleTargets = 0
    
    -- 获取附近所有玩家
    local players = GetActivePlayers()
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            
            -- 检查目标是否在视线范围内
            local distance = #(playerCoords - targetCoords)
            
            if distance > 0 and distance < 100.0 then -- 检测100米范围内的玩家
                -- 检查是否有视线
                local hasLineOfSight = HasEntityClearLosToEntity(playerPed, targetPed, 17)
                
                -- 检查是否在障碍物后面
                local rayHandle = StartShapeTestRay(playerCoords, targetCoords, 17, playerPed, 0)
                local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)
                
                local hitDistance = #(playerCoords - hitCoords)
                local targetDistance = #(playerCoords - targetCoords)
                
                -- 检查是否穿墙
                if not hasLineOfSight and hit and hitDistance < targetDistance - 0.5 then
                    -- 玩家在障碍物后面，但可能被透视
                    visibleTargets = visibleTargets + 1
                    
                    -- 检查穿墙距离
                    local wallDistance = targetDistance - hitDistance
                    if wallDistance > XDACE.Detections.wallhack.Parameters.MaxSeeThroughWallsDistance then
                        return {
                            type = "wallhack",
                            reason = string.format("穿墙透视检测 - 穿墙距离: %.2f米, 最大允许: %.2f米", wallDistance, XDACE.Detections.wallhack.Parameters.MaxSeeThroughWallsDistance),
                            severity = XDACE.Detections.wallhack.Severity,
                            data = {
                                targetDistance = targetDistance,
                                wallDistance = wallDistance,
                                targetPlayer = GetPlayerServerId(player)
                            }
                        }
                    end
                end
            end
        end
    end
    
    -- 检查可见目标数量
    if visibleTargets > XDACE.Detections.wallhack.Parameters.MaxVisibleTargets then
        return {
            type = "wallhack",
            reason = string.format("透视检测 - 可见目标数量异常: %d, 最大允许: %d", visibleTargets, XDACE.Detections.wallhack.Parameters.MaxVisibleTargets),
            severity = XDACE.Detections.wallhack.Severity,
            data = {
                visibleTargets = visibleTargets,
                maxAllowedTargets = XDACE.Detections.wallhack.Parameters.MaxVisibleTargets
            }
        }
    end
    
    return false
end