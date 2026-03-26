# AI 换图 - Windows 本地部署脚本
# 用于本地开发和测试环境部署

param(
    [string]$EnvType = "development",
    [switch]$NoInstall
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI 换图 - 部署脚本" -ForegroundColor Cyan
Write-Host "  环境：$EnvType" -ForegroundColor Cyan
Write-Host "  路径：$ProjectRoot" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 检查 Node.js
Write-Host "`n[1/5] 检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "  ✓ Node.js 已安装：$nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Node.js 未安装，请先安装 Node.js v22+" -ForegroundColor Red
    exit 1
}

# 2. 检查 PM2
Write-Host "`n[2/5] 检查 PM2..." -ForegroundColor Yellow
try {
    $pm2Version = pm2 --version 2>$null
    if ($pm2Version) {
        Write-Host "  ✓ PM2 已安装：$pm2Version" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ PM2 未安装，正在安装..." -ForegroundColor Yellow
        npm install -g pm2
        Write-Host "  ✓ PM2 安装完成" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ PM2 安装失败" -ForegroundColor Red
    exit 1
}

# 3. 安装依赖
if (-not $NoInstall) {
    Write-Host "`n[3/5] 安装依赖..." -ForegroundColor Yellow
    Set-Location "$ProjectRoot\server"
    npm install --production
    Write-Host "  ✓ 依赖安装完成" -ForegroundColor Green
} else {
    Write-Host "`n[3/5] 跳过依赖安装 (--NoInstall)" -ForegroundColor Yellow
}

# 4. 检查环境变量
Write-Host "`n[4/5] 检查环境变量..." -ForegroundColor Yellow
$envFile = "$ProjectRoot\server\.env"
if (Test-Path $envFile) {
    Write-Host "  ✓ .env 文件存在" -ForegroundColor Green
} else {
    Write-Host "  ⚠ .env 文件不存在，从 .env.example 复制..." -ForegroundColor Yellow
    if (Test-Path "$ProjectRoot\server\.env.example") {
        Copy-Item "$ProjectRoot\server\.env.example" $envFile
        Write-Host "  ! 请编辑 $envFile 填入真实的 API 密钥" -ForegroundColor Red
    } else {
        Write-Host "  ✗ .env.example 不存在" -ForegroundColor Red
        exit 1
    }
}

# 5. 启动服务
Write-Host "`n[5/5] 启动服务..." -ForegroundColor Yellow
Set-Location $ProjectRoot
pm2 delete ai-face-swap 2>$null
pm2 start ecosystem.config.js
pm2 save

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  部署完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n服务状态:" -ForegroundColor Cyan
pm2 status ai-face-swap
Write-Host "`n查看日志: pm2 logs ai-face-swap" -ForegroundColor Cyan
Write-Host "重启服务：pm2 restart ai-face-swap" -ForegroundColor Cyan
Write-Host "停止服务：pm2 stop ai-face-swap" -ForegroundColor Cyan
