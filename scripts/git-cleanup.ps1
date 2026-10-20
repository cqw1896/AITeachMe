# Git Pack File Unlink Error - Auto Retry Handler
# PowerShell Script

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Git Pack File Cleanup Helper" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Auto-detect repository path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoPath = $scriptDir

# If script is in AITeachMe root, the repo is current directory
# If script is in subdirectory, try to find .git
if (-not (Test-Path (Join-Path $repoPath ".git"))) {
    # Try common locations
    $candidates = @(
        "C:\AITeachMe\AITeachMe",
        (Join-Path $env:USERPROFILE "AITeachMe"),
        (Join-Path $env:USERPROFILE "Documents\AITeachMe"),
        $scriptDir
    )
    
    $found = $false
    foreach ($candidate in $candidates) {
        if ((Test-Path $candidate) -and (Test-Path (Join-Path $candidate ".git"))) {
            $repoPath = $candidate
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "[ERROR] Could not locate AITeachMe repository" -ForegroundColor Red
        Write-Host "[INFO] Script location: $scriptDir" -ForegroundColor Yellow
        Write-Host "[INFO] Searched paths:" -ForegroundColor Yellow
        foreach ($candidate in $candidates) {
            Write-Host "  - $candidate" -ForegroundColor Gray
        }
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "[INFO] Using repository: $repoPath" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $repoPath)) {
    Write-Host "[ERROR] Repository not found: $repoPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Set-Location $repoPath

Write-Host "[INFO] This script helps resolve Git pack file lock issues" -ForegroundColor Yellow
Write-Host ""

# Check for Git processes
Write-Host "[1/4] Checking for running Git processes..." -ForegroundColor Yellow
$gitProcesses = Get-Process | Where-Object { $_.ProcessName -like "*git*" }

if ($gitProcesses) {
    Write-Host "[WARN] Found running Git processes:" -ForegroundColor Yellow
    $gitProcesses | Format-Table ProcessName, Id, StartTime -AutoSize
    
    $response = Read-Host "Do you want to close these processes? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        foreach ($proc in $gitProcesses) {
            try {
                Stop-Process -Id $proc.Id -Force
                Write-Host "[OK] Closed process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
            } catch {
                Write-Host "[WARN] Could not close process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Yellow
            }
        }
        Start-Sleep -Seconds 2
    }
} else {
    Write-Host "[OK] No Git processes running" -ForegroundColor Green
}
Write-Host ""

# Run Git garbage collection
Write-Host "[2/4] Running Git garbage collection..." -ForegroundColor Yellow
git gc --auto
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Garbage collection completed" -ForegroundColor Green
} else {
    Write-Host "[WARN] Garbage collection had issues (non-fatal)" -ForegroundColor Yellow
}
Write-Host ""

# Check repository integrity
Write-Host "[3/4] Checking repository integrity..." -ForegroundColor Yellow
git fsck --full
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Repository integrity check passed" -ForegroundColor Green
} else {
    Write-Host "[WARN] Repository has some issues (usually safe to ignore)" -ForegroundColor Yellow
}
Write-Host ""

# Optimize repository
Write-Host "[4/4] Optimizing repository..." -ForegroundColor Yellow
git repack -a -d
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Repository optimized" -ForegroundColor Green
} else {
    Write-Host "[WARN] Optimization had issues" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "====================================" -ForegroundColor Green
Write-Host "[DONE] Cleanup Complete" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Re-run sync-upstream.ps1"
Write-Host "2. If you see the 'Should I try again? (y/n)' prompt, press 'y'"
Write-Host "3. Git will automatically retry and usually succeed"
Write-Host ""

Read-Host "Press Enter to exit"
