# 手动：提交并推送到 GitHub（与 .cursor/rules/github-auto-sync.mdc 约定一致）
# 用法: .\scripts\sync-github.ps1 [-Message "feat: xxx"]
param(
    [string]$Message = ""
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (-not $Message) {
    $Message = "chore: sync local changes $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

git status
$branch = (git branch --show-current).Trim()
if (-not $branch) { throw "Not a git branch" }

git add -A
$st = git status --porcelain
if (-not $st) {
    Write-Host "Nothing to commit."
    exit 0
}

git commit -m $Message
$remotes = git remote
if ($remotes -match '(?m)^github$') {
    git push github $branch
    Write-Host "Pushed to github/$branch"
} else {
    git push origin $branch
    Write-Host "Pushed to origin/$branch"
}
