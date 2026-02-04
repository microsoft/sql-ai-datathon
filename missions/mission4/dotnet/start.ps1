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
    Write-Host "✅ Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "⚠️ .env file not found at $envFile" -ForegroundColor Yellow
}

# Get current directory (dotnet folder) - handle both script and interactive execution
$dotnetDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Get mission4 directory (where dab-config.json is located)
$mission4Dir = Join-Path $dotnetDir ".."

# Start DAB in background (runs from mission4 folder)
Write-Host "Starting DAB on port 5000..." -ForegroundColor Cyan
$dabProcess = Start-Process -FilePath "dab" -ArgumentList "start" -WorkingDirectory $mission4Dir -PassThru -WindowStyle Minimized

# Wait for DAB to start
Start-Sleep -Seconds 3

# Start .NET app in background
Write-Host "Starting .NET app on port 5001..." -ForegroundColor Cyan
$dotnetProcess = Start-Process -FilePath "dotnet" -ArgumentList "run" -WorkingDirectory $dotnetDir -PassThru -WindowStyle Minimized

# Wait for .NET app to start
Start-Sleep -Seconds 3

# Open browser
Write-Host "🌐 Opening browser..." -ForegroundColor Cyan
Start-Process "http://localhost:5001/app"

Write-Host ""
Write-Host "✅ All services started!" -ForegroundColor Green
Write-Host ""
Write-Host "Services running:" -ForegroundColor White
Write-Host "  📊 DAB API:    http://localhost:5000/api/Products" -ForegroundColor Gray
Write-Host "  🔧 .NET API:   http://localhost:5001/swagger" -ForegroundColor Gray
Write-Host "  🌐 Frontend:   http://localhost:5001/app" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop all services..." -ForegroundColor Yellow

# Keep script running and handle cleanup on exit
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`n🛑 Stopping services..." -ForegroundColor Yellow
    if ($dabProcess -and !$dabProcess.HasExited) {
        Stop-Process -Id $dabProcess.Id -Force -ErrorAction SilentlyContinue
    }
    if ($dotnetProcess -and !$dotnetProcess.HasExited) {
        Stop-Process -Id $dotnetProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "✅ All services stopped" -ForegroundColor Green
}