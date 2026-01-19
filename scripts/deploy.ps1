# Deploy Script for Nova Health
# Usage: .\deploy.ps1 -TargetDir "C:\Path\To\Real\Project"

param (
    [Parameter(Mandatory = $true)]
    [string]$TargetDir
)

# Ensure Target Directory exists
if (-not (Test-Path $TargetDir)) {
    Write-Host "Error: Target directory '$TargetDir' does not exist." -ForegroundColor Red
    exit 1
}

Write-Host "Syncing files to $TargetDir..." -ForegroundColor Cyan

# Define source directory (current script location -> parent folder)
$SourceDir = (Get-Item $PSScriptRoot).Parent.FullName

# 1. Copy Backend API
Write-Host "Syncing backend-api..."
Robocopy "$SourceDir\backend-api" "$TargetDir\backend-api" /MIR /XD node_modules dist build coverage .git .idea .vscode /XF .env .env.* .DS_Store

# 2. Copy Mobile Frontend
Write-Host "Syncing mobile-frontend..."
Robocopy "$SourceDir\mobile-frontend" "$TargetDir\mobile-frontend" /MIR /XD build .dart_tool .idea .vscode ios/Pods ios/.symlinks android/.gradle /XF .env .env.* .DS_Store pubspec.lock

# 3. Copy Website Frontend
Write-Host "Syncing website-frontend..."
Robocopy "$SourceDir\website-frontend" "$TargetDir\website-frontend" /MIR /XD node_modules .next .vercel coverage .git .idea .vscode /XF .env .env.* .DS_Store

# 4. Copy Database/Infrastructure
Write-Host "Syncing database..."
Robocopy "$SourceDir\database" "$TargetDir\database" /MIR /XD .git .idea .vscode /XF .env .env.* .DS_Store

# 5. Copy Scripts
Write-Host "Syncing scripts..."
Robocopy "$SourceDir\scripts" "$TargetDir\scripts" /MIR /XD .git .idea .vscode /XF .env .env.* .DS_Store

# 6. Copy Root Files (README, etc.)
Write-Host "Syncing root files..."
Copy-Item "$SourceDir\README.md" "$TargetDir\README.md" -Force
Copy-Item "$SourceDir\.gitignore" "$TargetDir\.gitignore" -Force
if (Test-Path "$SourceDir\.agent") {
    Robocopy "$SourceDir\.agent" "$TargetDir\.agent" /MIR
}

Write-Host "---------------------------------------------------"
Write-Host "Success! Project structure synced to $TargetDir" -ForegroundColor Green
Write-Host "Note: Environment variables (.env) in the target directory were NOT touched."
Write-Host "---------------------------------------------------"
