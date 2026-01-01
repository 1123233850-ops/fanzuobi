-- 超级跳跃检测模块

XDACE.Detections.superjump = {
    Name = "Superjump",
    Enabled = Config.Detection.Superjump.Enabled,
    CheckInterval = Config.Detection.Superjump.CheckInterval,
    Severity = Config.Detection.Superjump.Severity,
    Parameters = Config.Detection.Superjump.Parameters,
    LastCheck = 0,
    jumpStartTime = 0,
    jumpStartPos = nil
}

function XDACE.Detections.superjump.Check()
    local currentTime = GetGameTimer()
    if currentTime - XDACE.Detections.superjump.LastCheck < XDACE.Detections.superjump.CheckInterval then
        return false
    end
    XDACE.Detections.superjump.LastCheck = currentTime
    
    local playerPed = PlayerPedId()
    local isJumping = IsPedJumping(playerPed)
    local isInAir = IsPedInAir(playerPed)
    
    -- 检测跳跃
    if isJumping and not XDACE.Detections.superjump.jumpStartPos then
        -- 记录跳跃起始位置和时间
        XDACE.Detections.superjump.jumpStartPos = GetEntityCoords(playerPed)
        XDACE.Detections.superjump.jumpStartTime = currentTime
    elseif (not isJumping and not isInAir) and XDACE.Detections.superjump.jumpStartPos then
        -- 跳跃结束，计算跳跃高度和距离
        local jumpEndPos = GetEntityCoords(playerPed)
        local jumpStartPos = XDACE.Detections.superjump.jumpStartPos
        local jumpTime = currentTime - XDACE.Detections.superjump.jumpStartTime
        
        -- 计算跳跃高度
        local jumpHeight = math.abs(jumpEndPos.z - jumpStartPos.z)
        
        -- 计算跳跃距离
        local jumpDistance = math.sqrt((jumpEndPos.x - jumpStartPos.x)^2 + (jumpEndPos.y - jumpStartPos.y)^2)
        
        -- 记录跳跃数据
        XDACE.Player.movementData.jumpHeight = jumpHeight
        XDACE.Player.movementData.jumpDistance = jumpDistance
        XDACE.Player.lastJump = currentTime
        
        -- 检测超级跳跃
        local violation = false
        local reason = ""
        
        -- 检查跳跃高度
        if jumpHeight > XDACE.Detections.superjump.Parameters.MaxJumpHeight then
            violation = true
            reason = string.format("跳跃高度异常 - 当前: %.2f米, 最大允许: %.2f米", jumpHeight, XDACE.Detections.superjump.Parameters.MaxJumpHeight)
        end
        
        -- 检查跳跃距离
        if not violation and jumpDistance > XDACE.Detections.superjump.Parameters.MaxJumpDistance then
            violation = true
            reason = string.format("跳跃距离异常 - 当前: %.2f米, 最大允许: %.2f米", jumpDistance, XDACE.Detections.superjump.Parameters.MaxJumpDistance)
        end
        
        -- 重置跳跃数据
        XDACE.Detections.superjump.jumpStartPos = nil
        XDACE.Detections.superjump.jumpStartTime = 0
        
        if violation then
            return {
                type = "superjump",
                reason = reason,
                severity = XDACE.Detections.superjump.Severity,
                data = {
                    jumpHeight = jumpHeight,
                    jumpDistance = jumpDistance,
                    jumpTime = jumpTime
                }
            }
        end
    end
    
    return false
end