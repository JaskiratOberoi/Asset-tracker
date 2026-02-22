# PowerShell deployment script for Hostinger
# Deploys the frontend dist folder to assets.stellarinfomatica.com

param(
    [string]$DeployUser = $env:DEPLOY_USER,
    [string]$DeployPath = $env:DEPLOY_PATH,
    [string]$RemoteHost = "assets.stellarinfomatica.com"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting deployment process..." -ForegroundColor Blue

# Configuration
if (-not $DeployUser) {
    $DeployUser = Read-Host "Enter your Hostinger SSH username"
}

if (-not $DeployPath) {
    $DeployPath = Read-Host "Enter remote path (e.g., /domains/stellarinfomatica.com/public_html/assets)"
}

$LocalDist = ".\frontend\dist"

# Check if dist folder exists, build if not
if (-not (Test-Path $LocalDist)) {
    Write-Host "📦 Building frontend..." -ForegroundColor Blue
    Set-Location frontend
    npm run build
    Set-Location ..
}

if (-not (Test-Path $LocalDist)) {
    Write-Host "❌ Error: dist folder not found after build" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed" -ForegroundColor Green

# Check if WinSCP or SCP is available
$scpAvailable = Get-Command scp -ErrorAction SilentlyContinue
$rsyncAvailable = Get-Command rsync -ErrorAction SilentlyContinue

if (-not $scpAvailable -and -not $rsyncAvailable) {
    Write-Host "⚠️  SCP or RSYNC not found. Using alternative method..." -ForegroundColor Yellow
    
    # Alternative: Create a zip file for manual upload
    $zipFile = "dist-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    Write-Host "📦 Creating zip file: $zipFile" -ForegroundColor Blue
    Compress-Archive -Path "$LocalDist\*" -DestinationPath $zipFile -Force
    Write-Host "✅ Zip file created: $zipFile" -ForegroundColor Green
    Write-Host "📤 Please upload this file to your Hostinger file manager" -ForegroundColor Yellow
    Write-Host "   Remote path: $DeployPath" -ForegroundColor Yellow
    exit 0
}

# Deploy using rsync (if available - requires WSL or Git Bash)
if ($rsyncAvailable) {
    Write-Host "📤 Uploading files using rsync..." -ForegroundColor Blue
    $rsyncCommand = "rsync -avz --delete `"$LocalDist/`" `"${DeployUser}@${RemoteHost}:${DeployPath}/`""
    Write-Host "Running: $rsyncCommand" -ForegroundColor Gray
    Invoke-Expression $rsyncCommand

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        Write-Host "🌐 Your site is live at: https://$RemoteHost" -ForegroundColor Green
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
        exit 1
    }
} elseif ($scpAvailable) {
    Write-Host "📤 Uploading files using SCP..." -ForegroundColor Blue
    ssh "${DeployUser}@${RemoteHost}" "mkdir -p '$DeployPath'"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create remote path" -ForegroundColor Red
        exit 1
    }
    scp -r "${LocalDist}\*" "${DeployUser}@${RemoteHost}:${DeployPath}/"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        Write-Host "🌐 Your site is live at: https://$RemoteHost" -ForegroundColor Green
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
        exit 1
    }
}
