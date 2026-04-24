# This script cleans up the Reflexa project for sharing
# It removes build artifacts, temporary logs, and caches to keep the file size small and avoid path errors.

Write-Host "Cleaning up project for sharing..." -ForegroundColor Cyan

# 1. Flutter Clean
if (Get-Command "flutter" -ErrorAction SilentlyContinue) {
    Write-Host "Running flutter clean..."
    flutter clean
} else {
    Write-Host "Flutter not found, skipping flutter clean. Manually deleting build/ and .dart_tool/..."
    Remove-Item -Path "build", ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Remove massive log files and temporary analyses
$logs = @(
    "analysis.txt",
    "analysis_full.txt",
    "analysis_output.txt",
    "analyze_output.txt",
    "build_error.txt",
    "build_log.txt",
    "detailed_build_log.txt",
    "detailed_build_log_utf8.txt",
    "final_analysis.txt"
)

foreach ($log in $logs) {
    if (Test-Path $log) {
        Write-Host "Removing $log..."
        Remove-Item $log -Force
    }
}

# 3. Remove Backend caches
Write-Host "Cleaning backend caches..."
Get-ChildItem -Path "backend" -Recurse -Filter "__pycache__" | Remove-Item -Recurse -Force
Get-ChildItem -Path "backend" -Recurse -Filter "*.pyc" | Remove-Item -Force

# 4. Remove IDE settings (optional but recommended for a clean share)
if (Test-Path ".idea") {
    Write-Host "Removing .idea folder..."
    Remove-Item ".idea" -Recurse -Force
}

Write-Host "`nProject is now clean! You can now zip the 'reflexa_app' folder and share it." -ForegroundColor Green
Write-Host "Suggestion: Right-click the 'reflexa_app' folder > Compress to ZIP file."
