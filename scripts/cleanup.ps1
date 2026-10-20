# Interactive File Cleanup for C:\AITeachMe
# PowerShell Script

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "AITeachMe Directory Cleanup Tool" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$baseDir = "C:\AITeachMe"

if (-not (Test-Path $baseDir)) {
    Write-Host "[ERROR] Directory not found: $baseDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $baseDir

# Define file categories
$logsToDelete = @(
    "backend.log",
    "frontend.log"
)

$oldScriptsToDelete = @(
    "提交MinerU到Fork_v2.bat",
    "同步上游更新.bat",
    "验证MinerU集成.bat",
    "打包迁移文件.bat",
    "git-push.txt"
)

$duplicateDocsToDelete = @(
    "Fork工作流完整指南.md",
    "MinerU集成维护指南.md",
    "脚本使用说明.md",
    "脚本问题修复报告.md",
    "手动推送到GitHub指南.md",
    "启动AITeachMe.md"
)

$optionalToDelete = @(
    "Git Pack File 错误解决.md",
    "推送到GitHub最终解决方案.md",
    "AITeachMe_VPS部署文档.md",
    "backend-env-backup.txt",
    "更新项目.bat"
)

# Function to check and list files
function Show-Files {
    param (
        [string]$Category,
        [array]$Files,
        [string]$Color = "Yellow"
    )
    
    Write-Host ""
    Write-Host "[$Category]" -ForegroundColor $Color
    Write-Host ("-" * 60) -ForegroundColor Gray
    
    $totalSize = 0
    $existingFiles = @()
    
    foreach ($file in $Files) {
        if (Test-Path $file) {
            $size = (Get-Item $file).Length
            $totalSize += $size
            $sizeKB = [math]::Round($size / 1KB, 1)
            Write-Host "  $file" -NoNewline
            Write-Host " ($sizeKB KB)" -ForegroundColor Gray
            $existingFiles += $file
        }
    }
    
    if ($existingFiles.Count -eq 0) {
        Write-Host "  (No files found)" -ForegroundColor Gray
    } else {
        $totalKB = [math]::Round($totalSize / 1KB, 1)
        Write-Host "  Total: $($existingFiles.Count) files, $totalKB KB" -ForegroundColor Cyan
    }
    
    return $existingFiles
}

# Show cleanup options
Write-Host "Cleanup Options:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [1] Conservative Cleanup (Recommended)" -ForegroundColor Green
Write-Host "      Delete: logs + old scripts + duplicate docs"
Write-Host "      Keep: all reference docs"
Write-Host "      Saves: ~480 KB"
Write-Host ""
Write-Host "  [2] Aggressive Cleanup" -ForegroundColor Yellow
Write-Host "      Delete: Option 1 + optional reference docs"
Write-Host "      Keep: only essential files"
Write-Host "      Saves: ~520 KB"
Write-Host ""
Write-Host "  [3] Custom Selection" -ForegroundColor Cyan
Write-Host "      Choose which categories to delete"
Write-Host ""
Write-Host "  [4] Preview Only (No Deletion)" -ForegroundColor Gray
Write-Host "      Just show what would be deleted"
Write-Host ""
Write-Host "  [0] Cancel" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Select option (0-4)"

if ($choice -eq "0") {
    Write-Host ""
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

# Show files to be deleted
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Files to be reviewed" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$logs = Show-Files "Log Files (safe to delete)" $logsToDelete "Yellow"
$oldScripts = Show-Files "Old Scripts (replaced by .ps1)" $oldScriptsToDelete "Yellow"
$duplicateDocs = Show-Files "Duplicate/Outdated Docs" $duplicateDocsToDelete "Yellow"
$optional = Show-Files "Optional Reference Docs" $optionalToDelete "Cyan"

# Determine what to delete based on choice
$filesToDelete = @()

switch ($choice) {
    "1" {
        # Conservative
        $filesToDelete = $logs + $oldScripts + $duplicateDocs
        Write-Host ""
        Write-Host "Mode: Conservative Cleanup" -ForegroundColor Green
    }
    "2" {
        # Aggressive
        $filesToDelete = $logs + $oldScripts + $duplicateDocs + $optional
        Write-Host ""
        Write-Host "Mode: Aggressive Cleanup" -ForegroundColor Yellow
    }
    "3" {
        # Custom
        Write-Host ""
        Write-Host "Custom Selection:" -ForegroundColor Cyan
        
        $response = Read-Host "Delete log files? (y/n)"
        if ($response -eq 'y') { $filesToDelete += $logs }
        
        $response = Read-Host "Delete old scripts? (y/n)"
        if ($response -eq 'y') { $filesToDelete += $oldScripts }
        
        $response = Read-Host "Delete duplicate docs? (y/n)"
        if ($response -eq 'y') { $filesToDelete += $duplicateDocs }
        
        $response = Read-Host "Delete optional reference docs? (y/n)"
        if ($response -eq 'y') { $filesToDelete += $optional }
    }
    "4" {
        # Preview only
        Write-Host ""
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host "Preview Mode - No files will be deleted" -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 0
    }
    default {
        Write-Host ""
        Write-Host "Invalid option." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Show summary and confirm
if ($filesToDelete.Count -eq 0) {
    Write-Host ""
    Write-Host "No files selected for deletion." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Yellow
Write-Host "Confirmation" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Files to be deleted:" -ForegroundColor Yellow
foreach ($file in $filesToDelete) {
    Write-Host "  - $file" -ForegroundColor Gray
}

$totalSize = 0
foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        $totalSize += (Get-Item $file).Length
    }
}
$totalKB = [math]::Round($totalSize / 1KB, 1)

Write-Host ""
Write-Host "Total: $($filesToDelete.Count) files, $totalKB KB" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Proceed with deletion? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host ""
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

# Create backup (optional)
Write-Host ""
$backup = Read-Host "Create backup before deletion? (y/n)"

if ($backup -eq 'y') {
    $backupDir = "C:\AITeachMe_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    foreach ($file in $filesToDelete) {
        if (Test-Path $file) {
            Copy-Item $file $backupDir -Force
        }
    }
    
    Write-Host "[OK] Backup created: $backupDir" -ForegroundColor Green
}

# Delete files
Write-Host ""
Write-Host "Deleting files..." -ForegroundColor Yellow

$deletedCount = 0
$failedCount = 0

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        try {
            Remove-Item $file -Force
            Write-Host "[OK] Deleted: $file" -ForegroundColor Green
            $deletedCount++
        } catch {
            Write-Host "[FAIL] Could not delete: $file" -ForegroundColor Red
            $failedCount++
        }
    }
}

# Summary
Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host "Cleanup Complete" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Deleted: $deletedCount files" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "Failed: $failedCount files" -ForegroundColor Red
}
Write-Host "Space saved: $totalKB KB" -ForegroundColor Cyan
Write-Host ""

if ($backup -eq 'y') {
    Write-Host "Backup location: $backupDir" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Remaining files in C:\AITeachMe:" -ForegroundColor Cyan
Get-ChildItem -File | Select-Object Name, @{Name="Size(KB)";Expression={[math]::Round($_.Length/1KB,1)}} | Format-Table -AutoSize

Read-Host "Press Enter to exit"
