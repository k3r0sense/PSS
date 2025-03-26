# Убедимся, что Winget установлен и доступен
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget не установлен. Установите его из Microsoft Store." -ForegroundColor Red
    exit 1
}

# Массив пакетов для установки
$packages = @(
    # Архиваторы
    "7zip.7zip",
    
    # Мессенджеры
    "9NKSQGP7F2NH",              # WhatsApp
    "Telegram.TelegramDesktop",
    
    # Dev tools
    "Docker.DockerDesktop",
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.VisualStudioCode",
    "Microsoft.WindowsTerminal",
    "PostgreSQL.PostgreSQL.17",
    
    # Графика
    "Figma.Figma",
    "Figma.FigmaAgent",
    
    # Системные утилиты
    "Microsoft.PowerToys",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    "RustDesk.RustDesk"
)

# Функция для установки пакетов с обработкой ошибок
function Install-Packages {
    param (
        [string[]]$Packages
    )
    
    $successCount = 0
    $failCount = 0
    $failedPackages = @()
    
    foreach ($package in $Packages) {
        Write-Host "`nУстанавливаю $package..." -ForegroundColor Cyan
        
        try {
            # Используем --silent для тихой установки и --accept-package-agreements для автоматического принятия соглашений
            $progressPreference = 'silentlyContinue'
            winget install --id $package --silent --accept-package-agreements --accept-source-agreements
            $progressPreference = 'Continue'
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$package успешно установлен!" -ForegroundColor Green
                $successCount++
            } else {
                throw "Ошибка установки (код $LASTEXITCODE)"
            }
        }
        catch {
            Write-Host "Ошибка при установке $package : $_" -ForegroundColor Red
            $failCount++
            $failedPackages += $package
        }
    }
    
    # Вывод итогов
    Write-Host "`nУстановка завершена!" -ForegroundColor Yellow
    Write-Host "Успешно установлено: $successCount" -ForegroundColor Green
    Write-Host "Не удалось установить: $failCount" -ForegroundColor Red
    
    if ($failedPackages.Count -gt 0) {
        Write-Host "`nСписок не установленных пакетов:" -ForegroundColor Red
        $failedPackages | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
        
        # Предложение повторить попытку для неустановленных пакетов
        $retry = Read-Host "`nПовторить попытку установки для этих пакетов? (y/n)"
        if ($retry -eq 'y') {
            Install-Packages -Packages $failedPackages
        }
    }
}

# Запускаем установку
Write-Host "Установка $($packages.Count) пакетов..." -ForegroundColor Yellow
Install-Packages -Packages $packages

# Дополнительные действия после установки
Write-Host "`nРекомендуемые действия после установки:" -ForegroundColor Magenta
Write-Host "- Перезагрузите компьютер для завершения установки некоторых компонентов" -ForegroundColor Magenta
Write-Host "- Настройте Docker Desktop и PostgreSQL по своему усмотрению" -ForegroundColor Magenta
