fx_version 'cerulean'
game 'gta5'

name 'xd-ace'
description 'FiveM 专业反作弊系统 - 支持 ESX、QB-Core、QBOX'
author '小东定制'
version '1.0.0'

-- 依赖关系
shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua',
    'server/detections/*.lua',
    'database/init.lua',
    'framework/detector.lua'
}

client_scripts {
    'client/main.lua',
    'client/detections/*.lua'
}

-- 网页资源
ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/style.css',
    'html/script.js'
}

-- 导出
exports {
    'GetPlayerData',
    'GetFramework',
    'GetConfig',
    'HandleViolation'
}

-- 服务器端导出
server_exports {
    'BanPlayer',
    'KickPlayer',
    'WarnPlayer',
    'GetViolations',
    'ClearViolations',
    'IsPlayerBanned'
}

-- 服务器信息
dependency 'oxmysql'

-- 脚本加载顺序
load_screen_manual_shutdown 'yes'
