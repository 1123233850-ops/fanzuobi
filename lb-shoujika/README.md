# LB手机运营商系统

基于ESX框架的手机运营商系统，支持手机号购买、激活、话费充值等功能。

## 功能特性

- ✅ 多种手机号套餐选择
- ✅ 手机号购买与管理
- ✅ 话费充值与查询
- ✅ 自动激活功能
- ✅ 替换默认手机号
- ✅ 消费记录查询
- ✅ 充值记录查询
- ✅ NPC交互界面
- ✅ 自动月租扣除
- ✅ 低余额警告
- ✅ **okokNotify通知系统集成**
- ✅ **管理员命令修改玩家手机号**

## 安装步骤

### 1. 数据库安装

将 `database.sql` 文件导入到您的数据库中：

```sql
source database.sql
```

或者直接在数据库管理工具中执行SQL文件。

### 2. 配置文件

编辑 `config.lua` 文件，根据您的服务器需求调整配置：

- NPC位置和外观
- 充值方式设置
- 购买和激活规则
- 通知设置

### 3. 资源启动

确保资源依赖已正确加载：
- `es_extended` (ESX框架)
- `lb-phone` (LB手机系统)
- `oxmysql` (MySQL异步库)
- `okokNotify` (通知系统) **新增**

在 `server.cfg` 中添加：

```
ensure okokNotify
ensure lb-phone
ensure lb-shoujika
```

**注意**: 确保 `lb-shoujika` 在 `lb-phone` 之后加载，`okokNotify` 需要先加载。

## 使用说明

### 玩家操作

1. **购买手机号**
   - 前往NPC位置（默认：洛圣都手机店）
   - 按 `E` 键打开运营商菜单
   - 选择"购买新号码"
   - 选择合适的套餐
   - 确认购买
   - **购买后会自动激活并安装到手机**
   - **拨打电话和接收电话都会使用新购买的号码**

2. **激活手机号**（如果购买时未自动激活）
   - 在"我的手机号"中选择未激活的号码
   - 点击"激活手机号"
   - 激活后会自动替换默认手机号

3. **充值话费**
   - 选择"充值话费"
   - 选择要充值的手机号
   - 选择充值方式（现金/银行）
   - 输入充值金额

4. **查看记录**
   - 在手机号详情中查看充值记录
   - 查看消费记录

### 管理员操作

**修改玩家手机号命令**

管理员可以使用以下命令修改指定玩家的手机号（支持1-7位号码）：

```
/setphone [玩家ID] [新手机号] [套餐ID(可选)]
```

**示例:**
```
/setphone 1 1234567          # 设置7位号码，使用默认套餐
/setphone 1 1234567 2        # 设置7位号码，指定套餐ID为2
/setphone 1 1                # 设置1位号码（管理员专用）
/setphone 1 123              # 设置3位号码（管理员专用）
```

**功能说明:**
- 只有管理员可以使用此命令
- **管理员可设置1-7位号码**（普通玩家购买时生成7-15位）
- 支持自定义1位号码（例如：`/setphone 1 1`）
- 可以指定套餐ID，如果不指定则使用默认套餐（ID: 1）
- 会自动检查手机号是否已被使用
- 会自动更新所有相关数据库表
- 会通知目标玩家手机号已修改
- 操作会记录在服务器日志中

**权限要求:**
- 需要在 `Config.AdminGroups` 中配置的管理员组
- 或配置在 `Config.AdminLicenses` 中的管理员许可证
- 默认支持: `admin`, `superadmin`

**设置玩家信用额度命令**

管理员可以使用以下命令设置指定玩家的信用额度：

```
/setcredit [玩家ID] [信用额度(分)]
```

**示例:**
```
/setcredit 1 10000           # 设置100元信用额度（10000分 = 100元）
/setcredit 1 50000           # 设置500元信用额度（50000分 = 500元）
```

**功能说明:**
- 只有管理员可以使用此命令
- 信用额度单位为"分"（100分 = 1元）
- 信用额度范围：0 - 100000分（0 - 1000元）
- 会自动计算并更新对应的信用评分
- 会通知目标玩家信用额度已更新
- 操作会记录在服务器日志中

**权限要求:**
- 需要在 `Config.AdminGroups` 中配置的管理员组
- 或配置在 `Config.AdminLicenses` 中的管理员许可证

**管理员充值命令**

管理员可以使用以下命令对指定号码进行充值：

```
/rechargephone [手机号] [充值金额(分)]
```

**示例:**
```
/rechargephone 1234567 10000        # 为号码1234567充值100元
/rechargephone 1 50000              # 为1位号码充值500元
```

**功能说明:**
- 只有管理员可以使用此命令
- 充值金额单位为"分"（100分 = 1元）
- 充值金额范围：10 - 10000分（0.1 - 100元）
- 会自动更新号码余额和信用评分
- 如果号码处于暂停状态，充值后会自动恢复服务
- 会通知号码所有者（如果在线）
- 操作会记录在服务器日志中

**权限要求:**
- 需要在 `Config.AdminGroups` 中配置的管理员组
- 或配置在 `Config.AdminLicenses` 中的管理员许可证

**自动收回欠费号码**

系统会自动检查并收回欠费超过指定天数的号码：

- **收回条件：**
  - 号码状态为 `suspended`（已暂停）或 `overdue`（欠费）
  - 余额为负数
  - 欠费天数达到配置的天数（默认7天）

- **收回操作：**
  - 将号码状态更新为 `expired`（已过期）
  - 从 `phone_phones` 表中移除号码（释放号码供二次出售）
  - 从 `phone_last_phone` 表中移除号码
  - 通知号码所有者（如果在线）

- **配置选项：**
  - `Config.AutoReclaim.Enabled` - 是否启用自动收回（默认: true）
  - `Config.AutoReclaim.OverdueDays` - 欠费多少天后收回（默认: 7天）
  - `Config.AutoReclaim.CheckInterval` - 检查间隔（默认: 1小时）
  - `Config.AutoReclaim.NotifyBeforeReclaim` - 收回前是否通知（默认: true）
  - `Config.AutoReclaim.ReclaimStatus` - 收回后的状态（默认: "expired"）

### 套餐配置

在数据库中可以直接添加或修改套餐：

```sql
INSERT INTO phone_operator_packages 
(name, description, price, initial_balance, monthly_fee, call_rate, sms_rate, data_rate) 
VALUES 
('新套餐', '套餐描述', 1500, 500, 150, 0.70, 0.25, 0.06);
```

## API 接口

### 服务器端导出

#### chargeBalance (扣除话费)

供 `lb-phone` 系统调用，在通话、短信等操作时自动扣除话费。

```lua
local success, newBalance = exports['lb-shoujika']:chargeBalance(
    phoneNumber,  -- 手机号
    amount,       -- 扣除金额
    chargeType,   -- 消费类型: 'call', 'sms', 'data', 'monthly_fee', 'other'
    description,  -- 描述
    metadata      -- 额外信息（可选）
)
```

**返回值:**
- `success` (boolean): 是否成功
- `newBalance` (number): 扣费后余额

### ESX回调

- `lb-shoujika:getPackages` - 获取套餐列表
- `lb-shoujika:getMyNumbers` - 获取我的手机号列表
- `lb-shoujika:purchaseNumber` - 购买手机号
- `lb-shoujika:activateNumber` - 激活手机号
- `lb-shoujika:rechargeBalance` - 充值话费
- `lb-shoujika:getBalance` - 获取余额
- `lb-shoujika:getRechargeHistory` - 获取充值记录
- `lb-shoujika:getChargeHistory` - 获取消费记录

## 与LB-Phone集成

要启用自动扣费功能，需要在 `lb-phone` 的相应功能中调用话费扣除接口。

### 通话扣费示例

在 `lb-phone/server/apps/default/phone.lua` 中，通话结束时添加：

```lua
-- 扣除话费
if exports['lb-shoujika'] then
    exports['lb-shoujika']:chargeBalance(
        callerNumber,
        callDuration * callRate, -- 根据通话时长和费率计算
        'call',
        '通话费用',
        { duration = callDuration, callee = calleeNumber }
    )
end
```

## 数据库表结构

### phone_operator_packages
运营商套餐表，存储所有可购买的套餐信息。

### phone_operator_numbers
玩家手机号表，存储玩家购买的所有手机号。

### phone_operator_recharges
充值记录表，记录所有充值历史。

### phone_operator_charges
消费记录表，记录所有话费消费。

## 配置说明

### 语言配置
- `Config.Locale` - 语言设置（默认: "zh-cn"）
  - `"zh-cn"` - 中文简体
  - `"en"` - 英文
- 语言文件位于 `locales/` 目录
  - `locales/zh-cn.lua` - 中文语言文件
  - `locales/en.lua` - 英文语言文件
- 使用 `_U('key', ...)` 函数获取翻译文本
- 如果当前语言不存在某个键，会自动回退到中文
- 可以轻松添加新语言：创建 `locales/xx.lua` 文件并添加翻译

### 通知系统配置
- `Config.Notification.System` - 通知系统类型: `"okokNotify"` 或 `"esx"`
- `Config.Notification.Duration` - 通知显示时长（毫秒）

### NPC配置
- `Config.NPC.Enabled` - 是否启用NPC
- `Config.NPC.Coords` - NPC位置坐标
- `Config.NPC.Model` - NPC模型

### 充值配置
- `Config.Recharge.MinAmount` - 最小充值金额
- `Config.Recharge.MaxAmount` - 最大充值金额
- `Config.Recharge.Methods` - 支持的充值方式

### 购买配置
- `Config.Purchase.AllowMultiple` - 是否允许购买多个手机号
- `Config.Purchase.AutoActivate` - 购买后是否自动激活（默认: true）
- `Config.Purchase.ReplaceDefault` - 是否替换默认手机号（默认: true）
- `Config.Purchase.AutoInstall` - 购买后是否自动安装到手机（默认: true）
- `Config.Purchase.ForceUpdate` - 是否强制更新所有相关表（包括不同标识符格式）（默认: true）
- `Config.Purchase.NotifyClient` - 是否通知客户端刷新手机号（默认: true）

### 管理员命令配置
- `Config.AdminCommands.Enabled` - 是否启用管理员命令
- `Config.AdminCommands.Command` - 命令名称（默认: `setphone`）
- `Config.AdminCommands.Permission` - 所需权限
- `Config.AdminCommands.MinPhoneLength` - 管理员可设置的最小手机号长度（默认: 1）
- `Config.AdminCommands.MaxPhoneLength` - 管理员可设置的最大手机号长度（默认: 7）
- `Config.AdminCommands.PlayerMinLength` - 普通玩家手机号最小长度（默认: 7）
- `Config.AdminCommands.PlayerMaxLength` - 普通玩家手机号最大长度（默认: 15）

### 管理员信用额度命令配置
- `Config.AdminCreditCommand.Enabled` - 是否启用信用额度命令
- `Config.AdminCreditCommand.Command` - 命令名称（默认: `setcredit`）
- `Config.AdminCreditCommand.Permission` - 所需权限

### 管理员充值命令配置
- `Config.AdminRechargeCommand.Enabled` - 是否启用充值命令
- `Config.AdminRechargeCommand.Command` - 命令名称（默认: `rechargephone`）
- `Config.AdminRechargeCommand.Permission` - 所需权限

### 自动收回配置
- `Config.AutoReclaim.Enabled` - 是否启用自动收回（默认: true）
- `Config.AutoReclaim.OverdueDays` - 欠费多少天后收回（默认: 7天）
- `Config.AutoReclaim.CheckInterval` - 检查间隔（毫秒，默认: 3600000，1小时）
- `Config.AutoReclaim.NotifyBeforeReclaim` - 收回前是否通知（默认: true）
- `Config.AutoReclaim.NotifyDaysBefore` - 收回前多少天通知（默认: 1天）
- `Config.AutoReclaim.ReclaimStatus` - 收回后的状态（"expired" 或 "deleted"）

## 故障排除

### 问题：购买后无法激活
- 检查数据库是否正确导入
- 检查玩家是否有足够的权限
- 查看服务器控制台错误信息

### 问题：NPC不显示
- 检查 `Config.NPC.Enabled` 是否为 `true`
- 检查NPC坐标是否正确
- 确认资源已正确启动

### 问题：无法充值
- 检查 `Config.Recharge.Methods` 配置
- 确认玩家有足够的现金/银行余额
- 检查充值金额是否在允许范围内

## 更新日志

### v1.5.0
- ✨ 添加完整的语言文件系统（支持中文和英文）
- ✨ 创建 `locales/zh-cn.lua` 和 `locales/en.lua` 语言文件
- ✨ 所有文本消息支持多语言切换
- 🔧 使用 `_U()` 函数统一管理所有文本
- 📝 更新文档说明语言配置

### v1.4.0
- ✨ 优化购买后自动激活逻辑，确保正确更新所有相关表
- ✨ 支持多标识符格式（license、char1等），确保号码正确安装
- ✨ 购买后自动更新 `phone_phones` 和 `phone_last_phone` 表
- ✨ 添加客户端事件通知，确保手机系统刷新
- 🔧 修复购买后号码不生效的问题
- 📝 更新文档说明自动安装功能

### v1.3.0
- ✨ 添加管理员充值命令 (`/rechargephone`)，支持对指定号码充值
- ✨ 实现欠费7天自动收回号码功能，释放号码供二次出售
- 🔧 优化自动收回逻辑，支持收回前通知
- 📝 更新文档说明新功能

### v1.2.0
- ✨ 管理员可设置1-7位号码（支持自定义1位号码）
- ✨ 添加管理员命令设置玩家信用额度 (`/setcredit`)
- ✨ 修改手机号命令支持指定套餐 (`/setphone [ID] [号码] [套餐ID]`)
- 🔧 优化管理员权限检查（支持许可证和组双重验证）
- 📝 更新文档说明新功能

### v1.1.0
- ✨ 集成 okokNotify 通知系统
- ✨ 添加管理员命令修改玩家手机号功能
- 🔧 优化通知显示效果
- 📝 更新配置文件说明

### v1.0.0
- 初始版本发布
- 支持手机号购买、激活、充值
- 支持话费记录查询
- 集成NPC交互界面

## 许可证

本资源仅供学习和研究使用。

## 支持

如有问题，请检查：
1. 服务器控制台错误信息
2. 数据库连接是否正常
3. 依赖资源是否正确加载

---

**注意**: 本系统需要与 `lb-phone` 配合使用，确保已正确安装并配置 `lb-phone` 资源。

