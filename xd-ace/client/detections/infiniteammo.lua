-- 无限弹药检测模块

XDACE.Detections.infiniteammo = {
    Name = "InfiniteAmmo",
    Enabled = Config.Detection.InfiniteAmmo.Enabled,
    CheckInterval = Config.Detection.InfiniteAmmo.CheckInterval,
    Severity = Config.Detection.InfiniteAmmo.Severity,
    Parameters = Config.Detection.InfiniteAmmo.Parameters,
    LastCheck = 0
}

function XDACE.Detections.infiniteammo.Check()
    local currentTime = GetGameTimer()
    if currentTime - XDACE.Detections.infiniteammo.LastCheck < XDACE.Detections.infiniteammo.CheckInterval then
        return false
    end
    XDACE.Detections.infiniteammo.LastCheck = currentTime
    
    local playerPed = PlayerPedId()
    local weapon = GetSelectedPedWeapon(playerPed)
    
    -- 检查是否持有武器
    if weapon ~= nil and weapon ~= 0 then
        local ammoCount = GetAmmoInPedWeapon(playerPed, weapon)
        local clipAmmo = GetAmmoInClip(playerPed, weapon)
        
        -- 记录当前弹药数量
        local lastAmmo = XDACE.Player.lastAmmo[weapon] or ammoCount
        XDACE.Player.lastAmmo[weapon] = ammoCount
        
        -- 检测无限弹药
        local violation = false
        local reason = ""
        
        -- 检查弹药数量是否异常增加
        if XDACE.Detections.infiniteammo.Parameters.CheckReloadBehavior then
            local lastReload = XDACE.Player.lastReload or GetGameTimer()
            local currentReload = GetGameTimer()
            
            -- 检查是否在短时间内重新装填了大量弹药
            if clipAmmo > 0 and lastAmmo < clipAmmo then
                -- 弹药数量异常增加
                violation = true
                reason = string.format("弹药异常增加 - 当前: %d, 之前: %d, 弹夹: %d", ammoCount, lastAmmo, clipAmmo)
            end
        end
        
        -- 检查弹药数量是否始终保持不变（射击后不减少）
        if not violation then
            -- 检查是否在射击但弹药不减少
            local isShooting = IsPlayerFreeAiming(PlayerId()) and IsControlPressed(0, 24) -- 24 = 鼠标左键
            if isShooting and ammoCount > 0 then
                -- 记录射击状态，后续可用于检测连续射击不减少弹药
                -- 这里简化处理，直接检查弹药数量是否异常
                if ammoCount > 1000 then
                    violation = true
                    reason = string.format("弹药数量异常 - 当前: %d", ammoCount)
                end
            end
        end
        
        if violation then
            return {
                type = "infiniteammo",
                reason = reason,
                severity = XDACE.Detections.infiniteammo.Severity,
                data = {
                    weapon = weapon,
                    ammoCount = ammoCount,
                    clipAmmo = clipAmmo,
                    lastAmmo = lastAmmo
                }
            }
        end
    end
    
    return false
end