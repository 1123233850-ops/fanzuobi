// 全局变量
let currentPage = 'dashboard';
let bansData = [];
let violationsData = [];
let playersData = [];
let settingsData = {};

// DOM 元素
const elements = {
    sidebarLinks: document.querySelectorAll('.sidebar nav ul li a'),
    contentSections: document.querySelectorAll('.content-section'),
    modals: document.querySelectorAll('.modal'),
    closeBtns: document.querySelectorAll('.close-btn'),
    addBanBtn: document.getElementById('add-ban-btn'),
    addBanModal: document.getElementById('add-ban-modal'),
    addBanForm: document.getElementById('add-ban-form'),
    searchInputs: document.querySelectorAll('.search-box input'),
    filterSelects: document.querySelectorAll('.filter-select'),
    saveSettingsBtn: document.getElementById('save-settings-btn')
};

// 初始化函数
function init() {
    console.log('XD-ACE 管理界面初始化...');
    
    // 初始化事件监听器
    initEventListeners();
    
    // 加载初始数据
    loadDashboardData();
    loadBansData();
    loadViolationsData();
    loadPlayersData();
    loadSettingsData();
    
    // 设置定时器，定期更新数据
    setInterval(() => {
        loadDashboardData();
        loadPlayersData();
    }, 10000); // 每10秒更新一次
    
    setInterval(() => {
        loadBansData();
        loadViolationsData();
    }, 30000); // 每30秒更新一次
}

// 初始化事件监听器
function initEventListeners() {
    // 侧边栏导航
    elements.sidebarLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const page = link.getAttribute('data-page');
            switchPage(page);
        });
    });
    
    // 模态框关闭按钮
    elements.closeBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const modal = btn.closest('.modal');
            closeModal(modal);
        });
    });
    
    // 点击模态框外部关闭
    window.addEventListener('click', (e) => {
        if (e.target.classList.contains('modal')) {
            closeModal(e.target);
        }
    });
    
    // 添加封禁按钮
    if (elements.addBanBtn) {
        elements.addBanBtn.addEventListener('click', () => {
            openModal(elements.addBanModal);
        });
    }
    
    // 添加封禁表单提交
    if (elements.addBanForm) {
        elements.addBanForm.addEventListener('submit', (e) => {
            e.preventDefault();
            handleAddBanFormSubmit();
        });
    }
    
    // 搜索输入框
    elements.searchInputs.forEach(input => {
        input.addEventListener('input', (e) => {
            const tableId = e.target.closest('.search-filter').getAttribute('data-table');
            handleSearch(tableId, e.target.value);
        });
    });
    
    // 筛选下拉框
    elements.filterSelects.forEach(select => {
        select.addEventListener('change', (e) => {
            const tableId = e.target.closest('.search-filter').getAttribute('data-table');
            handleFilter(tableId, e.target.value);
        });
    });
    
    // 保存设置按钮
    if (elements.saveSettingsBtn) {
        elements.saveSettingsBtn.addEventListener('click', handleSaveSettings);
    }
}

// 切换页面
function switchPage(page) {
    // 更新当前页面
    currentPage = page;
    
    // 更新侧边栏激活状态
    elements.sidebarLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('data-page') === page) {
            link.classList.add('active');
        }
    });
    
    // 显示对应内容区域
    elements.contentSections.forEach(section => {
        section.classList.remove('active');
        if (section.id === page) {
            section.classList.add('active');
        }
    });
    
    // 根据页面加载对应数据
    switch(page) {
        case 'dashboard':
            loadDashboardData();
            break;
        case 'bans':
            loadBansData();
            break;
        case 'violations':
            loadViolationsData();
            break;
        case 'players':
            loadPlayersData();
            break;
        case 'settings':
            loadSettingsData();
            break;
    }
}

// 打开模态框
function openModal(modal) {
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

// 关闭模态框
function closeModal(modal) {
    modal.classList.remove('active');
    document.body.style.overflow = 'auto';
    
    // 重置表单
    const form = modal.querySelector('form');
    if (form) {
        form.reset();
    }
}

// 加载控制面板数据
function loadDashboardData() {
    console.log('加载控制面板数据...');
    
    // 模拟数据 - 实际项目中应从API获取
    const stats = {
        totalPlayers: 125,
        onlinePlayers: 42,
        totalBans: 18,
        todayViolations: 3
    };
    
    // 更新统计卡片
    document.getElementById('total-players').textContent = stats.totalPlayers;
    document.getElementById('online-players').textContent = stats.onlinePlayers;
    document.getElementById('total-bans').textContent = stats.totalBans;
    document.getElementById('today-violations').textContent = stats.todayViolations;
}

// 加载封禁数据
function loadBansData() {
    console.log('加载封禁数据...');
    
    // 模拟数据 - 实际项目中应从API获取
    bansData = [
        { id: 1, playerName: 'Cheater123', steamId: 'STEAM_1:0:12345678', reason: '自瞄作弊', bannedBy: 'Admin01', bannedAt: '2025-12-01 14:30:00', expiresAt: '2026-12-01 14:30:00', status: 'banned' },
        { id: 2, playerName: 'SpeedHacker', steamId: 'STEAM_1:1:87654321', reason: '速度hack', bannedBy: 'Admin02', bannedAt: '2025-12-02 09:15:00', expiresAt: '2025-12-16 09:15:00', status: 'banned' },
        { id: 3, playerName: 'GodModeUser', steamId: 'STEAM_1:0:56789012', reason: '上帝模式', bannedBy: 'Admin01', bannedAt: '2025-12-03 16:45:00', expiresAt: '2025-12-24 16:45:00', status: 'banned' }
    ];
    
    renderBansTable(bansData);
}

// 渲染封禁表格
function renderBansTable(data) {
    const tableBody = document.querySelector('#bans-table tbody');
    if (!tableBody) return;
    
    tableBody.innerHTML = '';
    
    if (data.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="8" class="loading">暂无封禁记录</td></tr>';
        return;
    }
    
    data.forEach(ban => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${ban.id}</td>
            <td>${ban.playerName}</td>
            <td>${ban.steamId}</td>
            <td>${ban.reason}</td>
            <td>${ban.bannedBy}</td>
            <td>${ban.bannedAt}</td>
            <td>${ban.expiresAt}</td>
            <td>
                <span class="status-badge status-${ban.status}">${ban.status === 'banned' ? '已封禁' : '已解除'}</span>
                <button class="btn btn-danger btn-sm" onclick="removeBan(${ban.id})">解除</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

// 加载违规记录数据
function loadViolationsData() {
    console.log('加载违规记录数据...');
    
    // 模拟数据 - 实际项目中应从API获取
    violationsData = [
        { id: 1, playerName: 'Player1', steamId: 'STEAM_1:0:11111111', violationType: '自瞄检测', violationDetails: '完美精度检测触发', detectedAt: '2025-12-07 10:20:00', status: 'warning' },
        { id: 2, playerName: 'Player2', steamId: 'STEAM_1:1:22222222', violationType: '速度hack', violationDetails: '移动速度超过阈值', detectedAt: '2025-12-07 10:25:00', status: 'warning' },
        { id: 3, playerName: 'Player3', steamId: 'STEAM_1:0:33333333', violationType: '上帝模式', violationDetails: '无敌状态检测', detectedAt: '2025-12-07 10:30:00', status: 'banned' },
        { id: 4, playerName: 'Player4', steamId: 'STEAM_1:1:44444444', violationType: '穿墙检测', violationDetails: 'Z轴异常检测', detectedAt: '2025-12-07 10:35:00', status: 'warning' },
        { id: 5, playerName: 'Player5', steamId: 'STEAM_1:0:55555555', violationType: '无限弹药', violationDetails: '弹药数量异常', detectedAt: '2025-12-07 10:40:00', status: 'banned' }
    ];
    
    renderViolationsTable(violationsData);
}

// 渲染违规记录表格
function renderViolationsTable(data) {
    const tableBody = document.querySelector('#violations-table tbody');
    if (!tableBody) return;
    
    tableBody.innerHTML = '';
    
    if (data.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="7" class="loading">暂无违规记录</td></tr>';
        return;
    }
    
    data.forEach(violation => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${violation.id}</td>
            <td>${violation.playerName}</td>
            <td>${violation.steamId}</td>
            <td>${violation.violationType}</td>
            <td>${violation.violationDetails}</td>
            <td>${violation.detectedAt}</td>
            <td>
                <span class="status-badge status-${violation.status}">${violation.status === 'banned' ? '已封禁' : '警告'}</span>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

// 加载在线玩家数据
function loadPlayersData() {
    console.log('加载在线玩家数据...');
    
    // 模拟数据 - 实际项目中应从API获取
    playersData = [
        { id: 1, playerName: 'Player1', steamId: 'STEAM_1:0:11111111', ping: 45, playTime: '12h 30m', violations: 2, status: 'active' },
        { id: 2, playerName: 'Player2', steamId: 'STEAM_1:1:22222222', ping: 60, playTime: '8h 15m', violations: 0, status: 'active' },
        { id: 3, playerName: 'Player3', steamId: 'STEAM_1:0:33333333', ping: 35, playTime: '24h 45m', violations: 1, status: 'active' },
        { id: 4, playerName: 'Player4', steamId: 'STEAM_1:1:44444444', ping: 55, playTime: '5h 20m', violations: 0, status: 'active' },
        { id: 5, playerName: 'Player5', steamId: 'STEAM_1:0:55555555', ping: 40, playTime: '18h 10m', violations: 3, status: 'active' }
    ];
    
    renderPlayersTable(playersData);
}

// 渲染在线玩家表格
function renderPlayersTable(data) {
    const tableBody = document.querySelector('#players-table tbody');
    if (!tableBody) return;
    
    tableBody.innerHTML = '';
    
    if (data.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="7" class="loading">当前没有在线玩家</td></tr>';
        return;
    }
    
    data.forEach(player => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${player.id}</td>
            <td>${player.playerName}</td>
            <td>${player.steamId}</td>
            <td>${player.ping}ms</td>
            <td>${player.playTime}</td>
            <td>${player.violations}</td>
            <td>
                <span class="status-badge status-${player.status}">${player.status === 'active' ? '在线' : '离线'}</span>
                <button class="btn btn-warning btn-sm" onclick="warnPlayer(${player.id})">警告</button>
                <button class="btn btn-danger btn-sm" onclick="banPlayer(${player.id})">封禁</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

// 加载设置数据
function loadSettingsData() {
    console.log('加载设置数据...');
    
    // 模拟数据 - 实际项目中应从API获取
    settingsData = {
        aimbotDetection: true,
        speedhackDetection: true,
        godmodeDetection: true,
        wallhackDetection: true,
        infiniteAmmoDetection: true,
        aimbotThreshold: 95,
        speedhackThreshold: 1.5,
        violationBanThreshold: 3,
        checkInterval: 500
    };
    
    // 更新设置表单
    document.getElementById('aimbot-detection').checked = settingsData.aimbotDetection;
    document.getElementById('speedhack-detection').checked = settingsData.speedhackDetection;
    document.getElementById('godmode-detection').checked = settingsData.godmodeDetection;
    document.getElementById('wallhack-detection').checked = settingsData.wallhackDetection;
    document.getElementById('infinite-ammo-detection').checked = settingsData.infiniteAmmoDetection;
    document.getElementById('aimbot-threshold').value = settingsData.aimbotThreshold;
    document.getElementById('speedhack-threshold').value = settingsData.speedhackThreshold;
    document.getElementById('violation-ban-threshold').value = settingsData.violationBanThreshold;
    document.getElementById('check-interval').value = settingsData.checkInterval;
}

// 处理添加封禁表单提交
function handleAddBanFormSubmit() {
    console.log('处理添加封禁表单提交...');
    
    // 获取表单数据
    const formData = new FormData(elements.addBanForm);
    const banData = {
        playerName: formData.get('player-name'),
        steamId: formData.get('steam-id'),
        reason: formData.get('reason'),
        duration: formData.get('duration'),
        bannedBy: 'CurrentAdmin' // 实际项目中应从登录信息获取
    };
    
    // 模拟API请求 - 实际项目中应发送到后端
    console.log('添加封禁:', banData);
    
    // 关闭模态框
    closeModal(elements.addBanModal);
    
    // 重新加载封禁数据
    loadBansData();
    
    // 显示成功消息
    showMessage('封禁添加成功！', 'success');
}

// 处理保存设置
function handleSaveSettings() {
    console.log('处理保存设置...');
    
    // 获取设置数据
    settingsData = {
        aimbotDetection: document.getElementById('aimbot-detection').checked,
        speedhackDetection: document.getElementById('speedhack-detection').checked,
        godmodeDetection: document.getElementById('godmode-detection').checked,
        wallhackDetection: document.getElementById('wallhack-detection').checked,
        infiniteAmmoDetection: document.getElementById('infinite-ammo-detection').checked,
        aimbotThreshold: parseInt(document.getElementById('aimbot-threshold').value),
        speedhackThreshold: parseFloat(document.getElementById('speedhack-threshold').value),
        violationBanThreshold: parseInt(document.getElementById('violation-ban-threshold').value),
        checkInterval: parseInt(document.getElementById('check-interval').value)
    };
    
    // 模拟API请求 - 实际项目中应发送到后端
    console.log('保存设置:', settingsData);
    
    // 显示成功消息
    showMessage('设置保存成功！', 'success');
}

// 处理搜索
function handleSearch(tableId, searchTerm) {
    console.log('处理搜索:', tableId, searchTerm);
    
    let filteredData = [];
    
    // 根据表格ID获取对应数据
    switch(tableId) {
        case 'bans-table':
            filteredData = bansData.filter(ban => 
                ban.playerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                ban.steamId.toLowerCase().includes(searchTerm.toLowerCase()) ||
                ban.reason.toLowerCase().includes(searchTerm.toLowerCase())
            );
            renderBansTable(filteredData);
            break;
        case 'violations-table':
            filteredData = violationsData.filter(violation => 
                violation.playerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                violation.steamId.toLowerCase().includes(searchTerm.toLowerCase()) ||
                violation.violationType.toLowerCase().includes(searchTerm.toLowerCase())
            );
            renderViolationsTable(filteredData);
            break;
        case 'players-table':
            filteredData = playersData.filter(player => 
                player.playerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                player.steamId.toLowerCase().includes(searchTerm.toLowerCase())
            );
            renderPlayersTable(filteredData);
            break;
    }
}

// 处理筛选
function handleFilter(tableId, filterValue) {
    console.log('处理筛选:', tableId, filterValue);
    
    let filteredData = [];
    
    // 根据表格ID获取对应数据
    switch(tableId) {
        case 'bans-table':
            if (filterValue === 'all') {
                filteredData = bansData;
            } else {
                filteredData = bansData.filter(ban => ban.status === filterValue);
            }
            renderBansTable(filteredData);
            break;
        case 'violations-table':
            if (filterValue === 'all') {
                filteredData = violationsData;
            } else {
                filteredData = violationsData.filter(violation => violation.status === filterValue);
            }
            renderViolationsTable(filteredData);
            break;
        case 'players-table':
            if (filterValue === 'all') {
                filteredData = playersData;
            } else {
                filteredData = playersData.filter(player => player.status === filterValue);
            }
            renderPlayersTable(filteredData);
            break;
    }
}

// 移除封禁
function removeBan(banId) {
    console.log('移除封禁:', banId);
    
    // 模拟API请求 - 实际项目中应发送到后端
    bansData = bansData.map(ban => {
        if (ban.id === banId) {
            return { ...ban, status: 'unbanned' };
        }
        return ban;
    });
    
    // 更新表格
    renderBansTable(bansData);
    
    // 显示成功消息
    showMessage('封禁已移除！', 'success');
}

// 警告玩家
function warnPlayer(playerId) {
    console.log('警告玩家:', playerId);
    
    // 模拟API请求 - 实际项目中应发送到后端
    showMessage('玩家已警告！', 'success');
}

// 封禁玩家
function banPlayer(playerId) {
    console.log('封禁玩家:', playerId);
    
    // 可以打开添加封禁模态框并填充玩家信息
    const player = playersData.find(p => p.id === playerId);
    if (player) {
        document.getElementById('player-name').value = player.playerName;
        document.getElementById('steam-id').value = player.steamId;
        openModal(elements.addBanModal);
    }
}

// 显示消息
function showMessage(message, type = 'info') {
    // 创建消息元素
    const messageEl = document.createElement('div');
    messageEl.className = `message message-${type}`;
    messageEl.textContent = message;
    
    // 添加到页面
    document.body.appendChild(messageEl);
    
    // 3秒后自动移除
    setTimeout(() => {
        messageEl.remove();
    }, 3000);
}

// API 请求函数
async function apiRequest(endpoint, method = 'GET', data = null) {
    const url = `/api/${endpoint}`;
    const options = {
        method: method,
        headers: {
            'Content-Type': 'application/json'
        }
    };
    
    if (data) {
        options.body = JSON.stringify(data);
    }
    
    try {
        const response = await fetch(url, options);
        if (!response.ok) {
            throw new Error(`API请求失败: ${response.status}`);
        }
        return await response.json();
    } catch (error) {
        console.error('API请求错误:', error);
        showMessage('服务器错误，请稍后重试', 'error');
        return null;
    }
}

// 工具函数
function formatDate(date) {
    return new Date(date).toLocaleString('zh-CN');
}

function calculateTimeDiff(startDate, endDate) {
    const diff = new Date(endDate) - new Date(startDate);
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    return `${hours}h ${minutes}m`;
}

// DOM 加载完成后初始化
document.addEventListener('DOMContentLoaded', init);