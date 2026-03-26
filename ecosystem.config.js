module.exports = {
  apps: [{
    name: 'ai-face-swap',
    script: 'server/index.js',
    
    // Windows 本地开发环境
    cwd: process.env.LOCAL_APP_PATH || 'C:\\Users\\xiangjj\\.openclaw\\workspace\\projects\\ai-face-swap',

    // 单实例即可（SQLite 不支持多进程并发写）
    instances: 1,
    exec_mode: 'fork',

    // 自动重启
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',

    // 环境变量
    env: {
      NODE_ENV: 'development',
      PORT: 8080
    },

    // 日志
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',

    // 崩溃重启延迟（避免频繁重启）
    restart_delay: 5000,
    max_restarts: 10
  }]
};
