fx_version 'cerulean'
game 'gta5'


author 'LB Scripts'
description '小东开发LB手机运营商系统 - 支持ESX框架'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales/__resource.lua',
    'locales/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'es_extended',
    'lb-phone',
    'oxmysql',
    'okokNotify',
    'ox_target',
    'ox_lib'
}

