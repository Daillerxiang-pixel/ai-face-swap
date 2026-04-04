const path = require('path');

/** 测试服务器专用（与正式机 ecosystem.config.js 并存；PM2 应用名与端口不同，避免冲突） */
module.exports = {
  apps: [{
    name: 'ai-face-swap-test',
    script: 'server/index.js',
    cwd: process.env.LOCAL_APP_PATH || path.resolve(__dirname),

    instances: 1,
    exec_mode: 'fork',

    autorestart: true,
    watch: false,
    max_memory_restart: '512M',

    env: {
      NODE_ENV: 'development',
      PORT: 8082
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 8082
    },

    error_file: './logs/error.log',
    out_file: './logs/out.log',
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',

    restart_delay: 5000,
    max_restarts: 10
  }]
};
