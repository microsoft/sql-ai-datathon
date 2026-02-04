# Load environment variables from .env file
$envFile = "..\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "Loaded: $name" -ForegroundColor Gray
        }
    }
    Write-Host "[OK] Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "[WARN] .env file not found at $envFile" -ForegroundColor Yellow
}

# Get current directory (py folder) - handle both script and interactive execution
$pyDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Get mission4 directory (where dab-config.json is located)
$mission4Dir = Join-Path $pyDir ".."

# Start DAB in background (runs from mission4 folder)
Write-Host "Starting DAB on port 5000..." -ForegroundColor Cyan
$dabProcess = Start-Process -FilePath "dab" -ArgumentList "start" -WorkingDirectory $mission4Dir -PassThru -WindowStyle Minimized

# Wait for DAB to start
Start-Sleep -Seconds 3

# Start Python API
Write-Host "Starting Python API on port 8000..." -ForegroundColor Cyan
$pythonProcess = Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload" -WorkingDirectory $pyDir -PassThru -WindowStyle Minimized

# Wait for API to start
Start-Sleep -Seconds 3

# Open browser
Write-Host "Opening browser..." -ForegroundColor Cyan
Start-Process "http://localhost:8000/app"

Write-Host ""
Write-Host "[OK] Services started!" -ForegroundColor Green
Write-Host ""
Write-Host "Services running:" -ForegroundColor White
Write-Host "  DAB API:    http://localhost:5000/api/Products" -ForegroundColor Gray
Write-Host "  Python API: http://localhost:8000" -ForegroundColor Gray
Write-Host "  Swagger:    http://localhost:8000/docs" -ForegroundColor Gray
Write-Host "  Frontend:   http://localhost:8000/app" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop the services..." -ForegroundColor Yellow

# Keep script running and handle cleanup on exit
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "Stopping services..." -ForegroundColor Yellow
    if ($dabProcess -and !$dabProcess.HasExited) {
        Stop-Process -Id $dabProcess.Id -Force -ErrorAction SilentlyContinue
    }
    if ($pythonProcess -and !$pythonProcess.HasExited) {
        Stop-Process -Id $pythonProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Services stopped" -ForegroundColor Green
}