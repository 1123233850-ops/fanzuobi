-- xd-ace 反作弊系统配置文件
-- 支持 ESX、QB-Core、QBOX 框架

Config = {
    -- 调试模式
    Debug = {
        Enabled = true,
        Level = "info", -- info, warning, error, debug
        LogToFile = true,
        LogFilePath = "xd-ace.log"
    },
    
    -- 管理员设置
    Admin = {
        -- 管理员许可证列表
        Licenses = {
            "license:1234567890abcdef",
            "license:fedcba0987654321"
        },
        -- 管理员权限等级
        Levels = {
            [1] = "Moderator",
            [2] = "Admin",
            [3] = "Owner"
        },
        -- 管理员指令权限
        Commands = {
            ["xdace"] = 2,
            ["xdaceban"] = 3,
            ["xdacewarn"] = 2,
            ["xdacekick"] = 2,
            ["xdaceclear"] = 3
        }
    },
    
    -- 数据库设置
    Database = {
        -- 使用 oxmysql
        Driver = "oxmysql",
        -- 表前缀
        TablePrefix = "xd_ace_",
        -- 连接超时时间
        ConnectTimeout = 10000,
        -- 重试次数
        RetryCount = 3,
        -- 日志记录
        LogViolations = true,
        LogActions = true,
        LogBans = true
    },
    
    -- 反作弊核心设置
    AntiCheat = {
        -- 自动框架检测
        AutoDetectFramework = true,
        -- 支持的框架
        SupportedFrameworks = {
            "ESX",
            "QB-Core",
            "QBOX"
        },
        -- 检测间隔 (毫秒)
        scheduledDetection = {
            interval = 5, -- 秒
            enabled = true
        },
        -- 玩家数据刷新间隔
        PlayerDataRefreshInterval = 1000,
        -- 资源完整性检查
        ResourceIntegrity = {
            Enabled = true,
            Interval = 60000,
            ProtectedResources = {
                "es_extended",
                "qb-core",
                "oxmysql",
                "xd-ace"
            }
        },
        -- 管理员通知
        AdminAlerts = {
            Enabled = true,
            NotifyLevel = 1, -- 1: 所有违规, 2: 严重违规, 3: 只有封禁
            NotifyType = "chat", -- chat, discord, both
            DiscordWebhook = "https://discord.com/api/webhooks/your-webhook-url"
        },
        -- 违规处理
        ViolationActions = {
            -- 警告阈值
            WarnThreshold = 3,
            -- 踢人阈值
            KickThreshold = 5,
            -- 封禁阈值
            BanThreshold = 10,
            -- 违规积分重置时间 (小时)
            ViolationResetTime = 24,
            -- 违规记录保留时间 (天)
            ViolationRetentionDays = 30
        }
    },
    
    -- 检测模块配置
    Detection = {
        -- 瞄准辅助检测
        Aimbot = {
            Enabled = true,
            CheckInterval = 1000,
            -- 检测参数
            Parameters = {
                MaxTargetSwitchSpeed = 150, -- 最大目标切换速度 (度/秒)
                MaxAimAccuracy = 0.95, -- 最大瞄准准确率
                MaxAimSmoothness = 0.1, -- 最大瞄准平滑度
                MinAimTime = 100, -- 最小瞄准时间 (毫秒)
                MaxHeadshotRatio = 0.8 -- 最大爆头率
            },
            Severity = 3 -- 严重程度: 1-3
        },
        
        -- 速度hack检测
        Speedhack = {
            Enabled = true,
            CheckInterval = 500,
            Parameters = {
                MaxOnFootSpeed = 12, -- 最大步行速度 (m/s)
                MaxInVehicleSpeed = 300, -- 最大车辆速度 (km/h)
                MaxSwimSpeed = 2.5, -- 最大游泳速度 (m/s)
                SpeedTolerance = 1.2, -- 速度容忍度倍数
                MinMovingTime = 1000 -- 最小移动时间 (毫秒)
            },
            Severity = 3
        },
        
        -- 无敌模式检测
        Godmode = {
            Enabled = true,
            CheckInterval = 1000,
            Parameters = {
                HealthThreshold = 101, -- 健康值阈值
                ArmorThreshold = 101, -- 护甲值阈值
                DamageImmunityThreshold = 5 -- 连续免疫伤害次数
            },
            Severity = 3
        },
        
        -- 穿墙检测
        Wallhack = {
            Enabled = true,
            CheckInterval = 2000,
            Parameters = {
                MaxSeeThroughWallsDistance = 5, -- 最大穿墙距离 (m)
                MaxVisibleTargets = 10, -- 最大可见目标数
                CheckLineOfSight = true -- 检查视线
            },
            Severity = 3
        },
        
        -- 无限弹药检测
        InfiniteAmmo = {
            Enabled = true,
            CheckInterval = 3000,
            Parameters = {
                MaxAmmoChangeRate = 0.5, -- 最大弹药变化率
                CheckReloadBehavior = true -- 检查重新装填行为
            },
            Severity = 3
        },
        
        -- 超级跳跃检测
        Superjump = {
            Enabled = true,
            CheckInterval = 1000,
            Parameters = {
                MaxJumpHeight = 3.5, -- 最大跳跃高度 (m)
                MaxJumpDistance = 8, -- 最大跳跃距离 (m)
                JumpVelocityThreshold = 10 -- 跳跃速度阈值
            },
            Severity = 2
        },
        
        -- 无敌车辆检测
        InvincibleVehicle = {
            Enabled = true,
            CheckInterval = 2000,
            Parameters = {
                MaxVehicleHealth = 10000, -- 最大车辆健康值
                DamageImmunityThreshold = 3, -- 连续免疫伤害次数
                CheckVehicleMods = true -- 检查车辆改装
            },
            Severity = 3
        },
        
        -- 快速换弹检测
        FastReload = {
            Enabled = true,
            CheckInterval = 2000,
            Parameters = {
                MinReloadTime = 500, -- 最小重新装填时间 (毫秒)
                ReloadTimeTolerance = 0.5 -- 重新装填时间容忍度倍数
            },
            Severity = 2
        },
        
        -- 飞行检测
        Flying = {
            Enabled = true,
            CheckInterval = 1000,
            Parameters = {
                MaxHeightWithoutVehicle = 100, -- 无车辆最大高度 (m)
                CheckParachute = true, -- 检查降落伞
                CheckJetpack = true -- 检查喷气背包
            },
            Severity = 3
        },
        
        -- 传送检测
        Teleport = {
            Enabled = true,
            CheckInterval = 500,
            Parameters = {
                MaxTeleportDistance = 1000, -- 最大传送距离 (m)
                CheckVehicleTeleport = true, -- 检查车辆传送
                CheckPlayerTeleport = true -- 检查玩家传送
            },
            Severity = 3
        },
        
        -- 资源注入检测
        ResourceInjection = {
            Enabled = true,
            CheckInterval = 60000,
            Parameters = {
                CheckUnknownResources = true, -- 检查未知资源
                CheckModifiedResources = true, -- 检查修改的资源
                WhitelistedResources = {
                    "es_extended",
                    "qb-core",
                    "oxmysql",
                    "xd-ace"
                }
            },
            Severity = 3
        },
        
        -- 脚本注入检测
        ScriptInjection = {
            Enabled = true,
            CheckInterval = 5000,
            Parameters = {
                CheckEventHandlers = true, -- 检查事件处理器
                CheckNUI = true, -- 检查NUI
                CheckMemory = true, -- 检查内存
                CheckThreads = true -- 检查线程
            },
            Severity = 3
        },
        
        -- 物品复制检测
        ItemDuplication = {
            Enabled = true,
            CheckInterval = 5000,
            Parameters = {
                MaxItemChangeRate = 10, -- 最大物品变化率
                CheckItemSpawn = true, -- 检查物品生成
                CheckItemTransfer = true -- 检查物品转移
            },
            Severity = 3
        },
        
        -- 金钱修改检测
        MoneyHack = {
            Enabled = true,
            CheckInterval = 3000,
            Parameters = {
                MaxMoneyChange = 100000, -- 最大金钱变化
                CheckBankMoney = true, -- 检查银行金钱
                CheckCashMoney = true, -- 检查现金
                CheckDirtyMoney = true -- 检查脏钱
            },
            Severity = 3
        },
        
        -- 等级/经验修改检测
        LevelHack = {
            Enabled = true,
            CheckInterval = 5000,
            Parameters = {
                MaxLevelChange = 5, -- 最大等级变化
                MaxExpChange = 100000 -- 最大经验变化
            },
            Severity = 2
        }
    },
    
    -- 处罚设置
    Punishments = {
        -- 警告设置
        Warning = {
            Enabled = true,
            Message = "[XD-ACE] 你收到了一个警告: %s",
            Broadcast = false,
            LogToFile = true
        },
        -- 踢人设置
        Kick = {
            Enabled = true,
            Message = "[XD-ACE] 你因违反服务器规则被踢出: %s",
            Broadcast = false,
            LogToFile = true
        },
        -- 封禁设置
        Ban = {
            Enabled = true,
            Message = "[XD-ACE] 你因严重违反服务器规则被永久封禁: %s\n\n违规ID: %s\n封禁时间: 永久\n管理员: %s",
            Broadcast = true,
            LogToFile = true,
            BanType = "permanent", -- permanent, temporary
            DefaultBanDuration = 86400, -- 秒
            BanCommands = {
                ["permanent"] = "permanentban",
                ["temporary"] = "tempban"
            },
            -- 封禁理由
            BanReasons = {
                ["aimbot"] = "使用瞄准辅助",
                ["speedhack"] = "使用速度hack",
                ["godmode"] = "使用无敌模式",
                ["wallhack"] = "使用穿墙",
                ["infiniteammo"] = "使用无限弹药",
                ["superjump"] = "使用超级跳跃",
                ["invinciblevehicle"] = "使用无敌车辆",
                ["fastreload"] = "使用快速换弹",
                ["flying"] = "使用飞行hack",
                ["teleport"] = "使用传送hack",
                ["resourceinjection"] = "资源注入",
                ["scriptinjection"] = "脚本注入",
                ["itemduplication"] = "物品复制",
                ["moneyhack"] = "金钱修改",
                ["levelhack"] = "等级/经验修改"
            }
        }
    },
    
    -- 网络设置
    Network = {
        -- 延迟补偿
        LatencyCompensation = true,
        -- 最大延迟容忍度 (毫秒)
        MaxLatency = 500,
        -- 数据包丢失检测
        PacketLossDetection = {
            Enabled = true,
            Threshold = 0.3,
            CheckInterval = 10000
        },
        -- 速率限制
        RateLimiting = {
            Enabled = true,
            MaxEventsPerSecond = 100,
            MaxCommandsPerMinute = 100
        }
    },
    
    -- 界面设置
    UI = {
        -- 管理员面板
        AdminPanel = {
            Enabled = true,
            AccessKey = "F9",
            Locked = true,
            Password = "your-admin-password" -- 建议使用复杂密码
        },
        -- 玩家通知
        PlayerNotifications = {
            Enabled = true,
            Duration = 5000,
            Position = "bottom-right", -- top-left, top-right, bottom-left, bottom-right
            Type = "chat" -- chat, ui, both
        }
    },
    
    -- 性能设置
    Performance = {
        -- 最大检测线程数
        MaxDetectionThreads = 10,
        -- 检测优先级
        DetectionPriority = {
            "Godmode",
            "Aimbot",
            "Speedhack",
            "Wallhack",
            "InfiniteAmmo",
            "Superjump",
            "InvincibleVehicle",
            "FastReload",
            "Flying",
            "Teleport",
            "ResourceInjection",
            "ScriptInjection",
            "ItemDuplication",
            "MoneyHack",
            "LevelHack"
        },
        -- 内存优化
        MemoryOptimization = {
            Enabled = true,
            CleanupInterval = 300000, -- 毫秒
            MaxViolationHistory = 1000 -- 最大违规历史记录
        },
        --  CPU 优化
        CpuOptimization = {
            Enabled = true,
            MaxDetectionTime = 100, -- 最大检测时间 (毫秒)
            SleepBetweenDetections = 100 -- 检测间隔睡眠 (毫秒)
        }
    }
}

-- 日志记录函数
function Log(message, level)
    if not Config.Debug.Enabled then return end
    
    local levels = {
        info = 1,
        warning = 2,
        error = 3,
        debug = 4
    }
    
    local currentLevel = levels[Config.Debug.Level] or 1
    local messageLevel = levels[level] or 1
    
    if messageLevel <= currentLevel then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local logMessage = string.format("[%s] [%s] %s", timestamp, level:upper(), message)
        
        -- 输出到控制台
        print(logMessage)
        
        -- 写入文件
        if Config.Debug.LogToFile then
            local file = io.open(Config.Debug.LogFilePath, "a")
            if file then
                file:write(logMessage .. "\n")
                file:close()
            end
        end
    end
end
