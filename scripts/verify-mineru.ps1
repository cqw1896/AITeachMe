# Verify MinerU Integration
# PowerShell Script

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Verify MinerU Integration Status" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$repoPath = "C:\AITeachMe\AITeachMe"

if (-not (Test-Path $repoPath)) {
    Write-Host "[ERROR] Directory not found: $repoPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $repoPath

$allOk = $true

# Check MinerU files
Write-Host "[1/5] Checking MinerU files..." -ForegroundColor Yellow

if (Test-Path "backend\app\workflows\ingest\parsing\pdf_mineru_cloud.py") {
    $size = (Get-Item "backend\app\workflows\ingest\parsing\pdf_mineru_cloud.py").Length
    Write-Host "[OK] pdf_mineru_cloud.py exists ($size bytes)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] pdf_mineru_cloud.py not found" -ForegroundColor Red
    $allOk = $false
}

if (Test-Path "backend\app\workflows\ingest\parsing\pdf_mineru_local.py") {
    $size = (Get-Item "backend\app\workflows\ingest\parsing\pdf_mineru_local.py").Length
    Write-Host "[OK] pdf_mineru_local.py exists ($size bytes)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] pdf_mineru_local.py not found" -ForegroundColor Red
    $allOk = $false
}
Write-Host ""

# Check parsers.py configuration
Write-Host "[2/5] Checking parsers.py configuration..." -ForegroundColor Yellow

if (Test-Path "backend\app\workflows\ingest\parsing\parsers.py") {
    $parsersContent = Get-Content "backend\app\workflows\ingest\parsing\parsers.py" -Raw
    
    if ($parsersContent -match "mineru_cloud") {
        Write-Host "[OK] parsers.py contains mineru_cloud" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] parsers.py missing mineru_cloud" -ForegroundColor Red
        $allOk = $false
    }
    
    if ($parsersContent -match "pdf_mineru_local") {
        Write-Host "[OK] parsers.py contains pdf_mineru_local" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] parsers.py missing pdf_mineru_local" -ForegroundColor Red
        $allOk = $false
    }
} else {
    Write-Host "[FAIL] parsers.py not found" -ForegroundColor Red
    $allOk = $false
}
Write-Host ""

# Check Git commit
Write-Host "[3/5] Checking Git commit history..." -ForegroundColor Yellow

$mineruCommit = git log --oneline --all --grep="MinerU" -1 2>$null
if ($mineruCommit) {
    Write-Host "[OK] Git history contains MinerU commit: $mineruCommit" -ForegroundColor Green
} else {
    Write-Host "[WARN] No MinerU commit found (might use different message)" -ForegroundColor Yellow
}

$latestCommit = git log --oneline -1
Write-Host "  Latest commit: $latestCommit" -ForegroundColor Gray
Write-Host ""

# Summary
Write-Host "====================================" -ForegroundColor Cyan

if ($allOk) {
    Write-Host "[SUCCESS] MinerU Integration Complete" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Parser Chain (priority):" -ForegroundColor Cyan
    Write-Host "  1. mineru_cloud  (cloud, fast, 5-8 min/120 pages)"
    Write-Host "  2. mineru        (local, fallback, 10-40 min/120 pages)"
    Write-Host "  3. markitdown    (fallback, lightweight, text PDF only)"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Ensure backend service is running"
    Write-Host "  2. Visit http://127.0.0.1:5180"
    Write-Host "  3. Upload a PDF to test parsing"
} else {
    Write-Host "[FAIL] MinerU Integration Incomplete" -ForegroundColor Red
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Recovery Options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Restore from Git" -ForegroundColor Cyan
    Write-Host "  git log --oneline --all -- backend/app/workflows/ingest/parsing/"
    Write-Host "  git checkout 9a6d7d24 -- backend/app/workflows/ingest/parsing/"
    Write-Host ""
    Write-Host "Option 2: Re-clone from GitHub" -ForegroundColor Cyan
    Write-Host "  cd C:\"
    Write-Host "  git clone https://github.com/cqw1896/AITeachMe.git AITeachMe_Fresh"
}

Write-Host ""
Read-Host "Press Enter to exit"
