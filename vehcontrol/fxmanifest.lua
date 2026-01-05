fx_version 'adamant'
games { 'gta5' }

-- 作者信息
author 'Manvaril'
-- 脚本描述：车辆车门/车窗/座位/引擎/车内灯 NUI 控制脚本
description '车辆车门/车窗/座位/引擎/车内灯 NUI 控制脚本'
version '1.1.5'

-- UI页面路径
ui_page "html/vehui.html"

-- 资源文件列表
files {
  "html/vehui.html",
  "html/style.css",
  "html/img/doorFrontLeft.png",
  "html/img/doorFrontRight.png",
  "html/img/doorRearLeft.png",
  "html/img/doorRearRight.png",
  "html/img/frontHood.png",
  "html/img/ignition.png",
  "html/img/rearHood.png",
  "html/img/rearHood2.png",
  "html/img/seatFrontLeft.png",
  "html/img/windowFrontLeft.png",
  "html/img/windowFrontRight.png",
  "html/img/windowRearLeft.png",
  "html/img/windowRearRight.png",
  "html/img/interiorLight.png",
  "html/img/bombbay.png"
}

-- 客户端脚本
client_script {
  'config.lua',
  'client.lua'
}

-- 导出函数(供其他脚本调用)
export {
  'openExternal'
}
