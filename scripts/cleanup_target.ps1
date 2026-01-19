# Cleanup Script for Nova Health (Target Project)
# Usage: .\cleanup_target.ps1 -TargetDir "C:\Path\To\Real\Project"

param (
    [Parameter(Mandatory = $true)]
    [string]$TargetDir
)

if (-not (Test-Path $TargetDir)) {
    Write-Host "Error: Target directory '$TargetDir' does not exist." -ForegroundColor Red
    exit 1
}

$ItemsToDelete = @(
    "hms_frontend_flutter",
    "apps",
    "infra",
    "packages",
    "docs",
    "test-multi-org.js",
    "test-multi-org.ps1",
    "org_id.txt"
)

# Root markdown files to move to docs/archive
$DocsToArchive = @(
    "ADMIN_WEB_COMPLETE.md",
    "ADMIN_WEB_IMPLEMENTATION.md",
    "ADVANCED_RESCHEDULE_CANCEL_PLAN.md",
    "BACKEND_STATUS.md",
    "COMPLETE_IMPLEMENTATION_SUMMARY.md",
    "FLUTTER_IMPLEMENTATION_GUIDE.md",
    "FREE_DEPLOYMENT_GUIDE.md",
    "IMPLEMENTATION_SUMMARY.md",
    "MULTI_ORG_IMPLEMENTATION.md",
    "WORK_HOURS_IMPLEMENTATION.md"
)

Write-Host "Cleaning up '$TargetDir'..." -ForegroundColor Yellow

# Create archive directory
$ArchiveDir = "$TargetDir\docs\archive"
if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
}

# 1. Archive Markdown Files
foreach ($doc in $DocsToArchive) {
    $path = "$TargetDir\$doc"
    if (Test-Path $path) {
        Write-Host "Archiving $doc..."
        Move-Item $path "$ArchiveDir\$doc" -Force
    }
}

# 2. Delete Old Folders
foreach ($item in $ItemsToDelete) {
    $path = "$TargetDir\$item"
    if (Test-Path $path) {
        Write-Host "Removing $item..."
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "---------------------------------------------------"
Write-Host "Cleanup Complete! The project should now look clean." -ForegroundColor Green
Write-Host "---------------------------------------------------"
