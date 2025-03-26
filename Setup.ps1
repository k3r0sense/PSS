<#
.SYNOPSIS
    Установка базового набора приложений через Winget с дополнительной настройкой системы
.DESCRIPTION
    Скрипт устанавливает указанные приложения, настраивает WSL и Rust
    с проверкой зависимостей и обработкой ошибок
#>

#Requires -RunAsAdministrator

param (
    [switch]$SkipWSL,
    [switch]$SkipRust
)

# Настройки
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue' # Ускоряет работу Invoke-WebRequest

# Список пакетов для установки (Name или ID)
$packages = @(
    # Архиваторы
    "7zip.7zip",
    
    # Мессенджеры
    "9NKSQGP7F2NH", # WhatsApp ID
    "Telegram.TelegramDesktop",
    
    # Dev tools
    "Docker.DockerDesktop",
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.VisualStudioCode",
    "Microsoft.WindowsTerminal",
    "PostgreSQL.PostgreSQL",
    
    # Графика
    "Figma.Figma",
    "Figma.FigmaAgent",
    
    # Системные утилиты
    "Microsoft.PowerToys",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    "RustDesk.RustDesk"
)

function Test-WingetInstalled {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Winget не установлен. Попробуйте установить через Microsoft Store."
        return $false
    }
}

function Install-Package {
    param (
        [string]$PackageName
    )

    try {
        Write-Host "[+] Проверяем $PackageName" -ForegroundColor Cyan
        
        # Более надежная проверка установленного пакета
        $installed = winget list --exact --id $PackageName --accept-source-agreements | Out-String
        
        if ($installed -match $PackageName) {
            Write-Host "  ✔ Уже установлен" -ForegroundColor Green
            return
        }

        Write-Host "  ⚙ Устанавливаем..." -ForegroundColor Yellow
        winget install --exact --id $PackageName --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  Ошибка установки $PackageName (код $LASTEXITCODE)"
        }
        else {
            Write-Host "  ✔ Успешно установлен" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "  Ошибка при работе с $PackageName : $_"
    }
}

function Install-WSL {
    try {
        Write-Host "[+] Настраиваем WSL" -ForegroundColor Cyan
        
        if ($SkipWSL) {
            Write-Host "  ⚠ Пропуск по запросу" -ForegroundColor Yellow
            return
        }

        $feature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux"
        
        if (-not $feature.State -eq "Enabled") {
            Write-Host "  ⚙ Включаем подсистему WSL..." -ForegroundColor Yellow
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart | Out-Null
        }

        Write-Host "  ⚙ Устанавливаем WSL и Ubuntu..." -ForegroundColor Yellow
        wsl --install Ubuntu
        wsl --update
        
        Write-Host "  ✔ WSL настроен" -ForegroundColor Green
    }
    catch {
        Write-Warning "  Ошибка настройки WSL: $_"
    }
}

function Install-Rust {
    try {
        Write-Host "[+] Устанавливаем Rust" -ForegroundColor Cyan
        
        if ($SkipRust) {
            Write-Host "  ⚠ Пропуск по запросу" -ForegroundColor Yellow
            return
        }

        $tempFile = Join-Path $env:TEMP "rustup-init.exe"
        
        Write-Host "  ⚙ Скачиваем установщик..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile $tempFile
        
        Write-Host "  ⚙ Запускаем установку..." -ForegroundColor Yellow
        Start-Process -Wait -FilePath $tempFile -ArgumentList '-y'
        
        Write-Host "  ✔ Rust установлен" -ForegroundColor Green
    }
    catch {
        Write-Warning "  Ошибка установки Rust: $_"
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# Основной поток выполнения
try {
    # Проверка Winget
    if (-not (Test-WingetInstalled)) {
        exit 1
    }

    Write-Host "=== Начинаем установку пакетов ===" -ForegroundColor Magenta
    
    # Параллельная установка пакетов
    $jobs = foreach ($package in $packages) {
        Start-ThreadJob -ScriptBlock {
            param($pkg)
            Install-Package -PackageName $pkg
        } -ArgumentList $package -ThrottleLimit 4
    }
    
    $jobs | Wait-Job | Receive-Job
    
    # Дополнительные компоненты
    Install-WSL
    Install-Rust
    
    Write-Host "=== Установка завершена ===" -ForegroundColor Magenta
}
catch {
    Write-Warning "Критическая ошибка: $_"
    exit 1
}
finally {
    # Очистка
    Get-Job | Remove-Job -Force
}
