Config = {}

-- ============================================
-- 基础配置
-- ============================================
Config.Debug = false -- 调试模式

-- ============================================
-- 日志配置
-- ============================================
Config.Logging = {
    Enabled = true, -- 是否启用日志（设置为true以启用日志系统）
    Level = "info", -- 日志级别: "debug", "info", "warning", "error" (info级别会显示info/warning/error，debug级别会显示所有日志)
    ShowTimestamp = true, -- 是否显示时间戳
    ShowSource = true, -- 是否显示来源（客户端/服务器）
    Console = {
        Enabled = true, -- 是否输出到服务器控制台
        Colors = true -- 是否使用颜色（服务器端，FiveM控制台支持颜色代码）
    },
    F8 = {
        Enabled = true -- 是否输出到F8控制台（客户端，玩家按F8可查看）
    }
}

-- ============================================
-- NPC配置
-- ============================================
Config.NPC = {
    Enabled = true, -- 是否启用NPC
    Model = `s_m_y_ammucity_01`, -- NPC模型
    Coords = vector4(-537.15, -210.62, 37.65, 124.0), -- NPC位置
    Scenario = "WORLD_HUMAN_STAND_MOBILE", -- NPC动作
    Blip = {
        Enabled = true, -- 是否显示地图标记
        Sprite = 280, -- 标记图标（280=手机）
        Color = 3, -- 标记颜色（3=绿色）
        Scale = 0.8, -- 标记大小
        Name = "花海手机运营商" -- 如果使用语言文件，将在客户端动态获取
    }
}

-- ============================================
-- 手机号配置（靓号系统）
-- ============================================
Config.PhoneNumber = {
    Length = 7, -- 手机号长度（不含前缀）
    Prefixes = { -- 可选前缀
        "205",
        "907",
        "480",
        "520",
        "602"
    },
    Format = "({3}) {3}-{4}", -- 显示格式
    
    -- 靓号配置
    PremiumNumbers = {
        Enabled = true, -- 是否启用靓号系统
        Patterns = { -- 靓号模式
            -- 连号
            { pattern = "^(%d)%1%1%1%1%1%1$", name = "六连号", price_multiplier = 10.0 }, -- 1111111
            { pattern = "^(%d)%1%1%1%1%1", name = "五连号", price_multiplier = 5.0 }, -- 1111112
            { pattern = "^(%d)%1%1%1%1", name = "四连号", price_multiplier = 3.0 }, -- 1111123
            { pattern = "^(%d)%1%1%1", name = "三连号", price_multiplier = 2.0 }, -- 1111234
            
            -- 顺子
            { pattern = "^1234567$", name = "顺子号", price_multiplier = 8.0 },
            { pattern = "^7654321$", name = "倒顺号", price_multiplier = 8.0 },
            
            -- 重复数字
            { pattern = "^(%d)%1(%d)%2(%d)%3", name = "对子号", price_multiplier = 1.5 }, -- 1122334
            
            -- 特殊数字
            { pattern = "^8888888$", name = "超级靓号", price_multiplier = 20.0 },
            { pattern = "^6666666$", name = "超级靓号", price_multiplier = 20.0 },
            { pattern = "^9999999$", name = "超级靓号", price_multiplier = 20.0 },
            { pattern = "^8888", name = "四八号", price_multiplier = 3.0 },
            { pattern = "^6666", name = "四六号", price_multiplier = 3.0 },
            { pattern = "^9999", name = "四九号", price_multiplier = 3.0 },
            
            -- 尾号特殊
            { pattern = "8888$", name = "尾四八", price_multiplier = 2.5 },
            { pattern = "6666$", name = "尾四六", price_multiplier = 2.5 },
            { pattern = "9999$", name = "尾四九", price_multiplier = 2.5 },
        },
        MinPriceMultiplier = 1.0, -- 最低价格倍数
        MaxPriceMultiplier = 20.0 -- 最高价格倍数
    }
}

-- ============================================
-- 话费配置
-- ============================================
Config.Balance = {
    MinBalance = -999999, -- 最低余额（允许负数，但受信用额度限制）
    MaxBalance = 999999, -- 最高余额
    LowBalanceWarning = 50, -- 低余额警告阈值（元），低于此值会发送警告
    AutoSuspend = false, -- 余额不足时是否自动暂停服务
    AutoSuspendThreshold = 0, -- 自动暂停阈值（元），低于此值会自动暂停服务
    
    -- 余额检查配置
    CheckInterval = 300000, -- 余额检查间隔（毫秒），5分钟检查一次
    AllowNegative = true, -- 是否允许负数余额（在信用额度内）
    
    -- 余额恢复配置
    AutoResume = true, -- 充值后是否自动恢复服务
    ResumeThreshold = 10 -- 恢复服务阈值（元），余额达到此值以上自动恢复
}

-- ============================================
-- 信用额度配置
-- ============================================
Config.Credit = {
    InitialCredit = 1000, -- 初始信用额度（单位：分，10元）
    MinCredit = 0, -- 最低信用额度
    MaxCredit = 100000, -- 最高信用额度（1000元）
    
    -- 信用评分系统
    CreditScore = {
        InitialScore = 100, -- 初始信用评分
        MinScore = 0, -- 最低评分
        MaxScore = 1000, -- 最高评分
        
        -- 信用评分计算规则
        WeeklyPayment = 10, -- 每周按时缴费 +10分
        RechargeAmount = 0.1, -- 每充值1元 +0.1分
        OverduePenalty = -50, -- 欠费一次 -50分
        LatePayment = -20, -- 延迟缴费 -20分
    },
    
    -- 信用额度计算公式：credit_limit = credit_score * 10（分）
    CreditFormula = function(score)
        return math.floor(score * 10) -- 每1分 = 10分（0.1元）
    end
}

-- ============================================
-- 通话计费配置
-- ============================================
Config.CallBilling = {
    BillingUnit = 60, -- 计费单位（秒），60秒 = 1分钟
    RoundUp = true, -- 是否向上取整（不足1分钟按1分钟计）
    CheckBeforeCall = true, -- 拨打电话前检查余额和信用额度
    BlockOnOverdue = true, -- 欠费时阻止拨打电话
    
    -- 计费规则
    MinCallDuration = 0, -- 最小计费时长（秒），低于此值不计费
    MaxCallDuration = 3600, -- 最大单次通话时长（秒），超过此值自动挂断
    
    -- 免费分钟数配置
    UseFreeMinutes = true, -- 是否使用免费分钟数
    FreeMinutesPriority = true, -- 是否优先使用免费分钟数
    
    -- 计费通知
    NotifyOnCharge = false, -- 每次扣费时是否通知
    NotifyOnFreeCall = false -- 使用免费分钟数时是否通知
}

-- ============================================
-- 充值配置
-- ============================================
Config.Recharge = {
    MinAmount = 10, -- 最小充值金额（元）
    MaxAmount = 10000, -- 最大充值金额（元）
    Methods = { -- 充值方式
        cash = true, -- 现金
        bank = true, -- 银行
        card = false -- 银行卡（可选，需要额外实现）
    },
    Commission = 0.0, -- 充值手续费（0.0 = 无手续费，例如 0.02 = 2%手续费）
    
    -- 充值奖励配置
    Rewards = {
        Enabled = false, -- 是否启用充值奖励
        -- 充值奖励规则：{min_amount, bonus_percent}
        -- 例如：充值1000元以上，奖励5%
        Rules = {
            -- {1000, 0.05}, -- 充值1000元以上，奖励5%
            -- {5000, 0.10}, -- 充值5000元以上，奖励10%
        }
    }
}

-- ============================================
-- 购买配置
-- ============================================
Config.Purchase = {
    AllowMultiple = false, -- 是否允许玩家购买多个手机号
    AutoActivate = true, -- 购买后是否自动激活
    ReplaceDefault = true, -- 是否替换默认手机号
    RefundEnabled = false, -- 是否允许退款
    RefundPeriod = 7, -- 退款期限（天）
    
    -- 手机号安装配置
    AutoInstall = true, -- 购买后是否自动安装到手机
    ForceUpdate = true, -- 是否强制更新所有相关表（包括不同标识符格式）
    NotifyClient = true -- 是否通知客户端刷新手机号
}

-- ============================================
-- 激活配置
-- ============================================
Config.Activation = {
    RequirePayment = false, -- 激活是否需要付费
    ActivationFee = 0, -- 激活费用
    FreeTrial = false, -- 是否提供免费试用
    FreeTrialDays = 0 -- 免费试用天数
}

-- ============================================
-- 通知配置
-- ============================================
Config.Notifications = {
    LowBalance = true, -- 低余额通知
    RechargeSuccess = true, -- 充值成功通知
    PurchaseSuccess = true, -- 购买成功通知
    ActivationSuccess = true, -- 激活成功通知
    ExpirationWarning = true, -- 过期警告
    ExpirationWarningDays = 7, -- 过期前多少天提醒
    OverdueWarning = true, -- 欠费警告
    CreditUpdate = true -- 信用额度更新通知
}

-- ============================================
-- 语言配置
-- ============================================
Config.Locale = "zh-cn" -- 语言设置

-- ============================================
-- 通知系统配置
-- ============================================
Config.Notification = {
    System = "okokNotify", -- 通知系统: "okokNotify" 或 "esx"
    Duration = 5000, -- 通知显示时长（毫秒）
    
    -- 通知类型配置
    Types = {
        info = { color = "#3498db", icon = "info" }, -- 信息通知
        success = { color = "#2ecc71", icon = "check" }, -- 成功通知
        error = { color = "#e74c3c", icon = "times" }, -- 错误通知
        warning = { color = "#f39c12", icon = "exclamation" } -- 警告通知
    },
    
    -- 是否启用声音提示
    SoundEnabled = true,
    SoundTypes = {
        info = "default",
        success = "success",
        error = "error",
        warning = "warning"
    }
}

-- ============================================
-- 管理员配置
-- ============================================
Config.AdminOnly = false -- 是否仅管理员可操作
Config.AdminGroups = { -- 管理员组
    "admin",
    "superadmin"
}

-- 管理员许可证配置
Config.AdminLicenses = {
    -- 添加管理员许可证，例如：
    -- 'license:e8bb44b7e4fb8984c34fd55f7eb83a1fe045f8eb',
    -- 您可添加更多管理员许可证
    -- 格式: 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
}

-- 管理员命令配置
Config.AdminCommands = {
    Enabled = true,
    Command = "setphone", -- 命令名称：设置手机号
    Permission = "admin", -- 所需权限
    
    -- 管理员可设置的手机号长度范围
    MinPhoneLength = 1, -- 最小长度（仅管理员）
    MaxPhoneLength = 7, -- 最大长度（仅管理员）
    
    -- 普通玩家手机号长度范围
    PlayerMinLength = 7, -- 普通玩家最小长度
    PlayerMaxLength = 15 -- 普通玩家最大长度
}

-- 管理员设置信用额度命令配置
Config.AdminCreditCommand = {
    Enabled = true,
    Command = "setcredit", -- 命令名称：设置信用额度
    Permission = "admin" -- 所需权限
}

-- 管理员充值命令配置
Config.AdminRechargeCommand = {
    Enabled = true,
    Command = "rechargephone", -- 命令名称：充值指定号码
    Permission = "admin" -- 所需权限
}

-- 欠费自动收回配置
Config.AutoReclaim = {
    Enabled = true, -- 是否启用自动收回
    OverdueDays = 7, -- 欠费多少天后自动收回（天）
    CheckInterval = 3600000, -- 检查间隔（毫秒），默认1小时检查一次
    NotifyBeforeReclaim = true, -- 收回前是否通知玩家
    NotifyDaysBefore = 1, -- 收回前多少天通知
    ReclaimStatus = "expired" -- 收回后的状态：expired（已过期）或 deleted（已删除）
}

-- ============================================
-- 周租费配置
-- ============================================
Config.WeeklyFee = {
    Enabled = true, -- 是否启用周租费
    AutoDeduct = true, -- 是否自动扣除
    DeductDay = 1, -- 每周几扣除（1=周一，7=周日）
    DeductHour = 0, -- 扣除时间（小时，0-23）
    DeductMinute = 0, -- 扣除时间（分钟，0-59）
    GracePeriod = 3, -- 宽限期（天），超过宽限期仍未缴费则暂停服务
    NotifyBeforeDeduct = true, -- 扣除前是否通知
    NotifyDaysBefore = 1 -- 扣除前多少天通知
}

-- ============================================
-- 免费分钟数配置
-- ============================================
Config.FreeMinutes = {
    ResetDay = 1, -- 每周几重置（1=周一，7=周日）
    ResetHour = 0, -- 重置时间（小时）
    ResetMinute = 0, -- 重置时间（分钟）
    Priority = true -- 优先使用免费分钟数
}
