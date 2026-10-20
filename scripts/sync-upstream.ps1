# Sync Upstream Updates and Preserve MinerU Integration
# PowerShell Script

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Sync Upstream Updates" -ForegroundColor Cyan
Write-Host "Preserve MinerU Integration" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$repoPath = "C:\AITeachMe\AITeachMe"

# Check directory
if (-not (Test-Path $repoPath)) {
    Write-Host "[ERROR] Directory not found: $repoPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $repoPath

# [1/8] Check remote configuration
Write-Host "[1/8] Checking remote repository configuration..." -ForegroundColor Yellow
$upstreamExists = git remote -v | Select-String "upstream"
if (-not $upstreamExists) {
    Write-Host "[INFO] Upstream not configured, adding..." -ForegroundColor Yellow
    git remote add upstream https://github.com/aiteachme/AITeachMe.git
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Upstream repository added" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Failed to add upstream" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "[OK] Upstream repository configured" -ForegroundColor Green
}
Write-Host ""

# [2/8] Show current remotes
Write-Host "[2/8] Current remote repositories..." -ForegroundColor Yellow
git remote -v
Write-Host ""

# [3/8] Fetch upstream updates
Write-Host "[3/8] Fetching upstream updates..." -ForegroundColor Yellow
git fetch upstream
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Fetch successful" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Fetch failed, please check network" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

# [4/8] Show upstream commits
Write-Host "[4/8] Recent upstream commits (last 10)..." -ForegroundColor Yellow
git log upstream/main --oneline -10
Write-Host ""

# [5/8] Check current branch
Write-Host "[5/8] Current branch..." -ForegroundColor Yellow
$currentBranch = git branch --show-current
Write-Host "  Branch: $currentBranch" -ForegroundColor Gray
Write-Host ""

# [6/8] Merge upstream updates
Write-Host "[6/8] Merging upstream updates..." -ForegroundColor Yellow
Write-Host "[INFO] If conflicts occur, resolve them and re-run this script" -ForegroundColor Yellow
git merge upstream/main --no-edit

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Merge successful" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Merge failed, conflicts detected" -ForegroundColor Red
    Write-Host ""
    Write-Host "Conflict Resolution Steps:" -ForegroundColor Cyan
    Write-Host "1. Check conflicted files: git status"
    Write-Host "2. Edit files, search for <<<<<<< markers"
    Write-Host "3. Keep your MinerU integration code"
    Write-Host "4. Remove conflict markers (<<<<<<<, =======, >>>>>>>)"
    Write-Host "5. Save files"
    Write-Host "6. Commit resolution: git add . && git commit -m 'merge: Resolve conflicts'"
    Write-Host "7. Re-run this script"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

# [7/8] Push to your Fork
Write-Host "[7/8] Pushing to your Fork..." -ForegroundColor Yellow

# Push with auto-retry for pack file lock issues
$pushSuccess = $false
$maxRetries = 3

for ($i = 1; $i -le $maxRetries; $i++) {
    if ($i -gt 1) {
        Write-Host "[INFO] Retry attempt $i of $maxRetries..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
    
    $pushOutput = git push origin main 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Push successful" -ForegroundColor Green
        $pushSuccess = $true
        break
    } elseif ($pushOutput -match "Unlink of file") {
        Write-Host "[WARN] Pack file lock detected, retrying..." -ForegroundColor Yellow
        # Run quick cleanup
        git gc --auto 2>&1 | Out-Null
        Start-Sleep -Seconds 1
    } else {
        # Other error (authentication, etc.)
        break
    }
}

if (-not $pushSuccess -and $LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Push failed" -ForegroundColor Yellow
    
    if ($pushOutput -match "Unlink of file") {
        Write-Host ""
        Write-Host "Git pack file is locked (common on Windows)" -ForegroundColor Yellow
        Write-Host "Solutions:" -ForegroundColor Cyan
        Write-Host "1. Wait a few seconds and press 'y' if Git prompts again"
        Write-Host "2. Close any Git GUI tools (GitHub Desktop, TortoiseGit, etc.)"
        Write-Host "3. Run: .\git-cleanup.ps1"
        Write-Host "4. Or manually: git gc && git repack -a -d"
    } else {
        Write-Host "  Authentication may be required" -ForegroundColor Yellow
        Write-Host "  Please use GitHub Desktop to push manually" -ForegroundColor Yellow
        Write-Host "  Or refer to: Push to GitHub - Final Solution.md" -ForegroundColor Yellow
    }
}
Write-Host ""

# [8/8] Verify MinerU integration
Write-Host "[8/8] Verifying MinerU integration..." -ForegroundColor Yellow
$allOk = $true

if (Test-Path "backend\app\workflows\ingest\parsing\pdf_mineru_cloud.py") {
    Write-Host "[OK] pdf_mineru_cloud.py exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] pdf_mineru_cloud.py missing!" -ForegroundColor Red
    $allOk = $false
}

if (Test-Path "backend\app\workflows\ingest\parsing\pdf_mineru_local.py") {
    Write-Host "[OK] pdf_mineru_local.py exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] pdf_mineru_local.py missing!" -ForegroundColor Red
    $allOk = $false
}

if (Test-Path "backend\app\workflows\ingest\parsing\parsers.py") {
    $parsersContent = Get-Content "backend\app\workflows\ingest\parsing\parsers.py" -Raw
    if ($parsersContent -match "mineru_cloud") {
        Write-Host "[OK] parsers.py contains mineru_cloud" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] parsers.py missing mineru_cloud configuration!" -ForegroundColor Red
        $allOk = $false
    }
} else {
    Write-Host "[FAIL] parsers.py not found!" -ForegroundColor Red
    $allOk = $false
}

Write-Host ""

if ($allOk) {
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "[SUCCESS] Sync Complete!" -ForegroundColor Green
    Write-Host "MinerU Integration Preserved" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
} else {
    Write-Host "====================================" -ForegroundColor Red
    Write-Host "[WARNING] Sync Complete" -ForegroundColor Yellow
    Write-Host "But MinerU Integration Has Issues" -ForegroundColor Red
    Write-Host "====================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Recovery Options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Restore from Git history" -ForegroundColor Cyan
    Write-Host "  git log --oneline --all -- backend/app/workflows/ingest/parsing/"
    Write-Host "  git checkout 9a6d7d24 -- backend/app/workflows/ingest/parsing/"
    Write-Host ""
    Write-Host "Option 2: Re-clone from GitHub" -ForegroundColor Cyan
    Write-Host "  cd C:\"
    Write-Host "  git clone https://github.com/cqw1896/AITeachMe.git AITeachMe_Fresh"
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Restart backend service and test"
Write-Host "2. Upload a PDF to verify parsing"
Write-Host ""

Read-Host "Press Enter to exit"
