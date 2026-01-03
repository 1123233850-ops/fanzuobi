-- ============================================
-- LB手机运营商系统数据库
-- ============================================

-- 运营商手机号套餐表
CREATE TABLE IF NOT EXISTS `phone_operator_packages` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL COMMENT '套餐名称',
    `description` TEXT COMMENT '套餐描述',
    `price` INT(11) NOT NULL DEFAULT 0 COMMENT '套餐价格',
    `phone_number_prefix` VARCHAR(10) DEFAULT NULL COMMENT '手机号前缀（可选）',
    `initial_balance` INT(11) NOT NULL DEFAULT 0 COMMENT '初始话费余额',
    `weekly_fee` INT(11) NOT NULL DEFAULT 0 COMMENT '周租费（每周续费）',
    `free_minutes` INT(11) NOT NULL DEFAULT 0 COMMENT '免费通话分钟数（每周）',
    `call_rate` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '通话费率（每分钟，超出免费分钟数后）',
    `sms_rate` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '短信费率（每条）',
    `data_rate` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '流量费率（每MB）',
    `active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否启用',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 玩家购买的手机号记录表
CREATE TABLE IF NOT EXISTS `phone_operator_numbers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(100) NOT NULL COMMENT '玩家标识符',
    `phone_number` VARCHAR(15) NOT NULL COMMENT '手机号码（靓号）',
    `package_id` INT UNSIGNED NOT NULL COMMENT '套餐ID',
    `balance` INT(11) NOT NULL DEFAULT 0 COMMENT '当前话费余额（单位：分）',
    `credit_limit` INT(11) NOT NULL DEFAULT 1000 COMMENT '信用额度（单位：分，默认10元）',
    `used_free_minutes` INT(11) NOT NULL DEFAULT 0 COMMENT '已使用免费分钟数（本周）',
    `weekly_free_minutes_reset` TIMESTAMP NULL DEFAULT NULL COMMENT '免费分钟数重置时间',
    `status` ENUM('inactive', 'active', 'suspended', 'expired', 'overdue') NOT NULL DEFAULT 'inactive' COMMENT '状态：未激活/已激活/已暂停/已过期/欠费',
    `activated_at` TIMESTAMP NULL DEFAULT NULL COMMENT '激活时间',
    `expires_at` TIMESTAMP NULL DEFAULT NULL COMMENT '过期时间（NULL表示永久有效）',
    `last_recharge` TIMESTAMP NULL DEFAULT NULL COMMENT '最后充值时间',
    `last_weekly_fee` TIMESTAMP NULL DEFAULT NULL COMMENT '最后周租费扣除时间',
    `total_spent` INT(11) NOT NULL DEFAULT 0 COMMENT '总消费金额',
    `total_recharged` INT(11) NOT NULL DEFAULT 0 COMMENT '总充值金额',
    `credit_score` INT(11) NOT NULL DEFAULT 100 COMMENT '信用评分（用于计算信用额度）',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY (`phone_number`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_status` (`status`),
    FOREIGN KEY (`package_id`) REFERENCES `phone_operator_packages`(`id`) ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 话费充值记录表
CREATE TABLE IF NOT EXISTS `phone_operator_recharges` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL COMMENT '手机号码',
    `amount` INT(11) NOT NULL COMMENT '充值金额（单位：分）',
    `balance_before` INT(11) NOT NULL COMMENT '充值前余额',
    `balance_after` INT(11) NOT NULL COMMENT '充值后余额',
    `method` VARCHAR(50) DEFAULT 'cash' COMMENT '充值方式：cash/bank/card',
    `operator` VARCHAR(100) DEFAULT NULL COMMENT '操作员（如果是NPC充值）',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `idx_phone_number` (`phone_number`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_operator_numbers`(`phone_number`) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 话费消费记录表
CREATE TABLE IF NOT EXISTS `phone_operator_charges` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL COMMENT '手机号码',
    `type` ENUM('call', 'sms', 'data', 'weekly_fee', 'other') NOT NULL COMMENT '消费类型',
    `amount` INT(11) NOT NULL COMMENT '消费金额（单位：分）',
    `balance_before` INT(11) NOT NULL COMMENT '消费前余额',
    `balance_after` INT(11) NOT NULL COMMENT '消费后余额',
    `description` VARCHAR(255) DEFAULT NULL COMMENT '消费描述',
    `metadata` TEXT DEFAULT NULL COMMENT '额外信息（JSON格式）',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `idx_phone_number` (`phone_number`),
    KEY `idx_type` (`type`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_operator_numbers`(`phone_number`) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 通话记录表（用于计费）
CREATE TABLE IF NOT EXISTS `phone_operator_call_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL COMMENT '主叫手机号',
    `callee_number` VARCHAR(15) NOT NULL COMMENT '被叫手机号',
    `duration` INT(11) NOT NULL DEFAULT 0 COMMENT '通话时长（秒）',
    `charge_amount` INT(11) NOT NULL DEFAULT 0 COMMENT '计费金额（单位：分）',
    `used_free_minutes` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否使用了免费分钟数',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `idx_phone_number` (`phone_number`),
    KEY `idx_created_at` (`created_at`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 插入默认套餐数据（更新为周租费和免费分钟数）
INSERT INTO `phone_operator_packages` (`name`, `description`, `price`, `phone_number_prefix`, `initial_balance`, `weekly_fee`, `free_minutes`, `call_rate`, `sms_rate`, `data_rate`) VALUES
('基础套餐', '适合日常使用的经济型套餐，每周50分钟免费通话', 500, NULL, 1000, 500, 50, 1.00, 0.50, 0.10),
('标准套餐', '平衡价格与功能的套餐，每周100分钟免费通话', 1000, NULL, 3000, 1000, 100, 0.80, 0.30, 0.08),
('豪华套餐', '高端用户首选，每周200分钟免费通话', 2000, NULL, 8000, 2000, 200, 0.50, 0.20, 0.05),
('VIP套餐', '顶级套餐，每周500分钟免费通话', 5000, NULL, 20000, 5000, 500, 0.30, 0.10, 0.03)
ON DUPLICATE KEY UPDATE `weekly_fee` = VALUES(`weekly_fee`), `free_minutes` = VALUES(`free_minutes`);
