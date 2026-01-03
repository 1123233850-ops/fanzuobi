Locales = Locales or {}
Locales['en'] = {
    -- Common
    ['yes'] = 'Yes',
    ['no'] = 'No',
    ['confirm'] = 'Confirm',
    ['cancel'] = 'Cancel',
    ['close'] = 'Close',
    ['back'] = 'Back',
    ['success'] = 'Success',
    ['error'] = 'Error',
    ['warning'] = 'Warning',
    ['info'] = 'Info',
    
    -- NPC
    ['npc_interact'] = 'Press ~INPUT_CONTEXT~ to open phone operator',
    ['npc_blip_name'] = 'Phone Operator',
    
    -- Menu
    ['menu_operator'] = 'Phone Operator',
    ['menu_my_numbers'] = '📱 My Phone Numbers',
    ['menu_purchase'] = '🛒 Purchase New Number',
    ['menu_recharge'] = '💰 Recharge Balance',
    ['menu_purchase_title'] = 'Purchase Phone Number',
    ['menu_my_numbers_title'] = 'My Phone Numbers',
    ['menu_number_detail'] = 'Phone Number Details',
    ['menu_recharge_select'] = 'Select Phone Number to Recharge',
    ['menu_recharge_method'] = 'Select Recharge Method',
    ['menu_recharge_amount'] = 'Recharge Amount',
    ['menu_recharge_history'] = 'Recharge History',
    ['menu_charge_history'] = 'Charge History',
    
    -- Status
    ['status_active'] = '✅ Active',
    ['status_inactive'] = '⏸️ Inactive',
    ['status_suspended'] = '⛔ Suspended',
    ['status_expired'] = '❌ Expired',
    ['status_overdue'] = '⚠️ Overdue',
    
    -- Actions
    ['action_activate'] = '✅ Activate Phone Number',
    ['action_view_balance'] = '💰 Current Balance',
    ['action_view_recharge_history'] = '📋 Recharge History',
    ['action_view_charge_history'] = '📋 Charge History',
    
    -- Recharge Methods
    ['recharge_method_cash'] = '💵 Cash',
    ['recharge_method_bank'] = '🏦 Bank',
    ['recharge_method_card'] = '💳 Card',
    ['recharge_method_admin'] = '👤 Admin',
    
    -- Charge Types
    ['charge_type_call'] = '📞 Call',
    ['charge_type_sms'] = '💬 SMS',
    ['charge_type_data'] = '📶 Data',
    ['charge_type_monthly_fee'] = '📅 Monthly Fee',
    ['charge_type_weekly_fee'] = '📅 Weekly Fee',
    ['charge_type_other'] = 'Other',
    
    -- Notifications
    ['notify_no_numbers'] = 'You do not have a phone number yet',
    ['notify_no_packages'] = 'No packages available',
    ['notify_no_recharge_history'] = 'No recharge history',
    ['notify_no_charge_history'] = 'No charge history',
    ['notify_purchase_success'] = 'Purchase Successful',
    ['notify_purchase_failed'] = 'Purchase Failed',
    ['notify_activate_success'] = 'Activation Successful',
    ['notify_activate_failed'] = 'Activation Failed',
    ['notify_recharge_success'] = 'Recharge Successful',
    ['notify_recharge_failed'] = 'Recharge Failed',
    ['notify_phone_updated'] = 'Phone Number Updated',
    ['notify_phone_installed'] = 'Installation Complete',
    ['notify_low_balance'] = 'Low Balance',
    ['notify_service_suspended'] = 'Service Suspended',
    ['notify_service_resumed'] = 'Service Resumed',
    ['notify_credit_updated'] = 'Credit Limit Updated',
    ['notify_credit_increased'] = 'Credit Increased',
    ['notify_number_reclaimed'] = 'Number Reclaimed',
    ['notify_number_will_reclaim'] = 'Number Will Be Reclaimed',
    
    -- Purchase
    ['purchase_confirm'] = 'Confirm purchase %s?',
    ['purchase_phone_number'] = 'Your phone number is: %s',
    ['purchase_initial_balance'] = 'Initial balance: $%d',
    ['purchase_premium_number'] = '✨ Premium Number Type: %s (Price Multiplier: %.1fx)',
    ['purchase_already_owned'] = 'You already own a phone number',
    ['purchase_insufficient_funds'] = 'Insufficient funds, need $%d',
    ['purchase_package_not_found'] = 'Package not found or disabled',
    
    -- Activation
    ['activate_success'] = 'Phone number activated successfully!',
    ['activate_failed'] = 'Activation failed',
    ['activate_not_owned'] = 'Phone number does not exist or does not belong to you',
    ['activate_already_active'] = 'Phone number is already active',
    ['activate_insufficient_funds'] = 'Insufficient funds to pay activation fee',
    
    -- Recharge
    ['recharge_amount_range'] = 'Recharge Amount ($%d - $%d)',
    ['recharge_amount_invalid'] = 'Amount must be between $%d and $%d',
    ['recharge_current_balance'] = 'Current balance: $%d',
    ['recharge_commission'] = 'Recharge amount: $%d, Commission: $%d',
    ['recharge_insufficient_cash'] = 'Insufficient cash',
    ['recharge_insufficient_bank'] = 'Insufficient bank balance',
    ['recharge_method_not_supported'] = 'Recharge method not supported: %s',
    ['recharge_phone_not_found'] = 'Phone number does not exist',
    ['recharge_failed'] = 'Recharge failed',
    
    -- Balance
    ['balance_low_warning'] = 'Low phone balance! Current balance: $%d, please recharge in time',
    ['balance_negative'] = 'Insufficient balance, cannot make calls',
    ['balance_auto_suspend'] = 'Your phone service has been suspended due to insufficient balance ($%d), please recharge in time',
    
    -- Credit
    ['credit_score_increased'] = 'Recharged $%d, credit score +%d, current credit limit: $%d',
    ['credit_limit_set'] = 'Your credit limit has been set to: $%d',
    ['credit_limit_updated'] = 'Admin has set your credit limit to: $%d',
    
    -- Admin Commands
    ['admin_no_permission'] = 'You do not have permission to use this command',
    ['admin_command_format_error'] = 'Command format error',
    ['admin_player_not_found'] = 'Player not found',
    ['admin_phone_number_used'] = 'Phone number is already in use',
    ['admin_phone_number_format_error'] = 'Phone number format error',
    ['admin_phone_number_length_error'] = 'Admin can set phone number length between %d-%d digits',
    ['admin_phone_number_digits_only'] = 'Phone number can only contain digits',
    ['admin_package_not_found'] = 'Package not found',
    ['admin_operation_success'] = 'Operation successful',
    ['admin_phone_updated'] = 'Phone number updated',
    ['admin_credit_range_error'] = 'Credit limit must be between %d - %d',
    ['admin_credit_set_success'] = 'Set player %s (ID: %d) credit limit to: $%d (Credit Score: %d)',
    ['admin_recharge_success'] = 'Recharged phone number %s with $%d',
    ['admin_recharge_amount_error'] = 'Recharge amount must be between %d - %d',
    
    -- Auto Reclaim
    ['reclaim_notification'] = 'Your phone number %s has been overdue for %d days and will be reclaimed. Please recharge in time!',
    ['reclaim_executed'] = 'Your phone number %s has been reclaimed due to %d days of overdue without recharge',
    
    -- Other
    ['unknown'] = 'Unknown',
    ['loading'] = 'Loading...',
    ['please_wait'] = 'Please wait...',
}

