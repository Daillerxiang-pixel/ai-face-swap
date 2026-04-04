const path = require('path');

module.exports = {
  apps: [{
    name: 'ai-face-swap',
    script: 'server/index.js',
    // 项目根目录（Linux 与 Windows 通用；也可用环境变量覆盖）
    cwd: process.env.LOCAL_APP_PATH || path.resolve(__dirname),

    // 单实例即可（SQLite 不支持多进程并发写）
    instances: 1,
    exec_mode: 'fork',

    // 自动重启
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',

    // 环境变量（本地: pm2 start ecosystem.config.js；生产: pm2 start ecosystem.config.js --env production）
    env: {
      NODE_ENV: 'development',
      PORT: 8080
    },
    env_production: {
      NODE_ENV: 'production',
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
