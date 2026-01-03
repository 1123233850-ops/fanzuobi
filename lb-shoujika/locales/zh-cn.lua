Locales = Locales or {}
Locales['zh-cn'] = {
    -- 通用
    ['yes'] = '是',
    ['no'] = '否',
    ['confirm'] = '确认',
    ['cancel'] = '取消',
    ['close'] = '关闭',
    ['back'] = '返回',
    ['success'] = '成功',
    ['error'] = '错误',
    ['warning'] = '警告',
    ['info'] = '信息',
    
    -- NPC
    ['npc_interact'] = '按 ~INPUT_CONTEXT~ 打开手机运营商',
    ['npc_blip_name'] = '花海手机运营商',
    
    -- 菜单
    ['menu_operator'] = '手机运营商',
    ['menu_my_numbers'] = '📱 我的手机号',
    ['menu_purchase'] = '🛒 购买新号码',
    ['menu_recharge'] = '💰 充值话费',
    ['menu_purchase_title'] = '购买手机号',
    ['menu_my_numbers_title'] = '我的手机号',
    ['menu_number_detail'] = '手机号详情',
    ['menu_recharge_select'] = '选择要充值的手机号',
    ['menu_recharge_method'] = '选择充值方式',
    ['menu_recharge_amount'] = '充值金额',
    ['menu_recharge_history'] = '充值记录',
    ['menu_charge_history'] = '消费记录',
    
    -- 状态
    ['status_active'] = '✅ 已激活',
    ['status_inactive'] = '⏸️ 未激活',
    ['status_suspended'] = '⛔ 已暂停',
    ['status_expired'] = '❌ 已过期',
    ['status_overdue'] = '⚠️ 欠费',
    
    -- 操作
    ['action_activate'] = '✅ 激活手机号',
    ['action_view_balance'] = '💰 当前余额',
    ['action_view_recharge_history'] = '📋 充值记录',
    ['action_view_charge_history'] = '📋 消费记录',
    
    -- 充值方式
    ['recharge_method_cash'] = '💵 现金',
    ['recharge_method_bank'] = '🏦 银行',
    ['recharge_method_card'] = '💳 银行卡',
    ['recharge_method_admin'] = '👤 管理员',
    
    -- 消费类型
    ['charge_type_call'] = '📞 通话',
    ['charge_type_sms'] = '💬 短信',
    ['charge_type_data'] = '📶 流量',
    ['charge_type_monthly_fee'] = '📅 月租',
    ['charge_type_weekly_fee'] = '📅 周租',
    ['charge_type_other'] = '其他',
    
    -- 通知消息
    ['notify_no_numbers'] = '您还没有手机号',
    ['notify_no_packages'] = '暂无可用套餐',
    ['notify_no_recharge_history'] = '暂无充值记录',
    ['notify_no_charge_history'] = '暂无消费记录',
    ['notify_purchase_success'] = '购买成功',
    ['notify_purchase_failed'] = '购买失败',
    ['notify_activate_success'] = '激活成功',
    ['notify_activate_failed'] = '激活失败',
    ['notify_recharge_success'] = '充值成功',
    ['notify_recharge_failed'] = '充值失败',
    ['notify_phone_updated'] = '手机号已更新',
    ['notify_phone_installed'] = '已安装完成',
    ['notify_low_balance'] = '余额不足',
    ['notify_service_suspended'] = '服务已暂停',
    ['notify_service_resumed'] = '服务已恢复',
    ['notify_credit_updated'] = '信用额度已更新',
    ['notify_credit_increased'] = '信用提升',
    ['notify_number_reclaimed'] = '号码已被收回',
    ['notify_number_will_reclaim'] = '号码即将被收回',
    
    -- 购买相关
    ['purchase_confirm'] = '确认购买 %s?',
    ['purchase_phone_number'] = '您的手机号是：%s',
    ['purchase_initial_balance'] = '初始余额：$%d',
    ['purchase_premium_number'] = '✨ 靓号类型：%s (价格倍数: %.1fx)',
    ['purchase_already_owned'] = '您已经拥有一个手机号',
    ['purchase_insufficient_funds'] = '余额不足，需要 $%d',
    ['purchase_package_not_found'] = '套餐不存在或已停用',
    
    -- 激活相关
    ['activate_success'] = '手机号激活成功！',
    ['activate_failed'] = '激活失败',
    ['activate_not_owned'] = '手机号不存在或不属于您',
    ['activate_already_active'] = '手机号已经激活',
    ['activate_insufficient_funds'] = '余额不足，无法支付激活费用',
    
    -- 充值相关
    ['recharge_amount_range'] = '充值金额 ($%d - $%d)',
    ['recharge_amount_invalid'] = '金额必须在 $%d 到 $%d 之间',
    ['recharge_current_balance'] = '当前余额：$%d',
    ['recharge_commission'] = '充值金额：$%d，手续费：$%d',
    ['recharge_insufficient_cash'] = '现金不足',
    ['recharge_insufficient_bank'] = '银行余额不足',
    ['recharge_method_not_supported'] = '不支持的充值方式: %s',
    ['recharge_phone_not_found'] = '手机号不存在',
    ['recharge_failed'] = '充值失败',
    
    -- 余额相关
    ['balance_low_warning'] = '话费余额不足！当前余额：$%d，建议及时充值',
    ['balance_negative'] = '余额不足，无法拨打电话',
    ['balance_auto_suspend'] = '由于余额不足（$%d），您的手机服务已被暂停，请及时充值',
    
    -- 信用相关
    ['credit_score_increased'] = '充值 $%d，信用评分 +%d，当前信用额度：$%d',
    ['credit_limit_set'] = '已将您的信用额度设置为: $%d',
    ['credit_limit_updated'] = '管理员已将您的信用额度设置为: $%d',
    
    -- 管理员命令
    ['admin_no_permission'] = '您没有权限使用此命令',
    ['admin_command_format_error'] = '命令格式错误',
    ['admin_player_not_found'] = '玩家不存在',
    ['admin_phone_number_used'] = '手机号已被使用',
    ['admin_phone_number_format_error'] = '手机号格式错误',
    ['admin_phone_number_length_error'] = '管理员可设置的手机号长度必须在%d-%d位之间',
    ['admin_phone_number_digits_only'] = '手机号只能包含数字',
    ['admin_package_not_found'] = '套餐不存在',
    ['admin_operation_success'] = '操作成功',
    ['admin_phone_updated'] = '手机号已修改',
    ['admin_credit_range_error'] = '信用额度必须在 %d - %d 之间',
    ['admin_credit_set_success'] = '已将玩家 %s (ID: %d) 的信用额度设置为: $%d (信用评分: %d)',
    ['admin_recharge_success'] = '已为手机号 %s 充值 $%d',
    ['admin_recharge_amount_error'] = '充值金额必须在 %d - %d 之间',
    
    -- 自动收回
    ['reclaim_notification'] = '您的手机号 %s 已欠费 %d 天，即将被收回。请及时充值！',
    ['reclaim_executed'] = '您的手机号 %s 因欠费 %d 天未充值已被收回',
    
    -- 其他
    ['unknown'] = '未知',
    ['loading'] = '加载中...',
    ['please_wait'] = '请稍候...',
}

