Framework = {}
Framework.Current = nil
Framework.Core = nil

-- 框架类型枚举
Framework.Types = {
    ESX = 'esx',
    QB = 'qb',
    QBX = 'qbx',
    NONE = 'none'
}

-- 框架配置
Framework.Config = {
    esx = {
        resource = 'es_extended',
        getObject = function() return exports['es_extended']:getSharedObject() end
    },
    qb = {
        resource = 'qb-core',
        getObject = function() return exports['qb-core']:GetCoreObject() end
    },
    qbx = {
        resource = 'qbx-core',
        getObject = function() return exports['qbx-core']:GetCoreObject() end
    }
}

-- 检测当前使用的框架
function Framework.Detect()
    local detectedFramework = Framework.Types.NONE
    local coreObject = nil
    
    -- 尝试检测QBOX框架
    if GetResourceState('qbx-core') == 'started' then
        detectedFramework = Framework.Types.QBX
        coreObject = Framework.Config.qbx.getObject()
        print('[XD ACE] ✅ 检测到 QBOX 框架')
    
    -- 尝试检测QB-Core框架
    elseif GetResourceState('qb-core') == 'started' then
        detectedFramework = Framework.Types.QB
        coreObject = Framework.Config.qb.getObject()
        print('[XD ACE] ✅ 检测到 QB-Core 框架')
    
    -- 尝试检测ESX框架
    elseif GetResourceState('es_extended') == 'started' then
        detectedFramework = Framework.Types.ESX
        coreObject = Framework.Config.esx.getObject()
        print('[XD ACE] ✅ 检测到 ESX 框架')
    
    -- 未检测到任何支持的框架
    else
        print('[XD ACE] ⚠️ 未检测到支持的框架，将使用基础模式运行')
    end
    
    Framework.Current = detectedFramework
    Framework.Core = coreObject
    
    return detectedFramework, coreObject
end

-- 获取当前框架
function Framework.GetCurrent()
    if not Framework.Current then
        Framework.Detect()
    end
    return Framework.Current
end

-- 获取框架核心对象
function Framework.GetCoreObject()
    if not Framework.Core then
        Framework.Detect()
    end
    return Framework.Core
end

-- 检查是否为ESX框架
function Framework.IsESX()
    return Framework.GetCurrent() == Framework.Types.ESX
end

-- 检查是否为QB框架
function Framework.IsQB()
    return Framework.GetCurrent() == Framework.Types.QB
end

-- 检查是否为QBOX框架
function Framework.IsQBX()
    return Framework.GetCurrent() == Framework.Types.QBX
end

-- 初始化框架检测
CreateThread(function()
    Framework.Detect()
end)