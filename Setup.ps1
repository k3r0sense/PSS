# Checking Winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget isn't installed. Install it from MS Store" -ForegroundColor Red
    exit 1
}

$packages = @(
    # Necessary components
    "7zip.7zip",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    
    # Communication
    # "9NKSQGP7F2NH", # WhatsApp
    "Telegram.TelegramDesktop",
    
    # Dev tools
    "Docker.DockerDesktop",
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.VisualStudioCode",
    "Microsoft.WindowsTerminal",
    "PostgreSQL.PostgreSQL.17",
    
    # Graphics
    "Figma.Figma",
    "Figma.FigmaAgent",
    
    # Utilities
    "Microsoft.PowerToys",
    "RustDesk.RustDesk"
)

function Install-Packages {
    param (
        [string[]]$Packages
    )
    
    $successCount = 0
    $failCount = 0
    $failedPackages = @()
    
    foreach ($package in $Packages) {
        Write-Host "`Installing $package..." -ForegroundColor Cyan
        
        try {
            $ProgressPreference = 'silentlyContinue'
            winget install --id $package --silent --accept-package-agreements --accept-source-agreements
            $ProgressPreference = 'Continue'
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$package installed!" -ForegroundColor Green
                $successCount++
            }
            else {
                throw "Error $LASTEXITCODE"
            }
        }
        catch {
            Write-Host "Error while installation $package : $_" -ForegroundColor Red
            $failCount++
            $failedPackages += $package
        }
    }
    
    Write-Host "`nInstall complete!" -ForegroundColor Yellow
    Write-Host "Installed: $successCount" -ForegroundColor Green
    Write-Host "Not installed: $failCount" -ForegroundColor Red
    
    if ($failedPackages.Count -gt 0) {
        Write-Host "`List of installed packages:" -ForegroundColor Red
        $failedPackages | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
        
        # Answer to install packages again
        $retry = Read-Host "`Try to reinstall unsuccessful packages? (y/n)"
        if ($retry -eq 'y') {
            Install-Packages -Packages $failedPackages
        }
    }
}

# Installation
Write-Host "Installing $($packages.Count) packages..." -ForegroundColor Yellow
Install-Packages -Packages $packages

# Recommended actions
Write-Host "`Recommended actions after installation:" -ForegroundColor Magenta
Write-Host "- Restart your computer to complete installation completely" -ForegroundColor Magenta
Write-Host "- Setup Docker Desktop and PostgreSQL" -ForegroundColor Magenta
