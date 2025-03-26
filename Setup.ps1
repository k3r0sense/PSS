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
}
finally {
    # Очистка
    Get-Job | Remove-Job -Force
}

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAqV3rog4f2gY1B
# 3EUGYlNwPPaNIupY7Al5lTSyQulSwqCCAyIwggMeMIICBqADAgECAhBEklUIQAnQ
# gkLGtOnc/LQFMA0GCSqGSIb3DQEBCwUAMCcxJTAjBgNVBAMMHFBvd2VyU2hlbGwg
# Q29kZSBTaWduaW5nIENlcnQwHhcNMjUwMzI2MDk0MDE2WhcNMjYwMzI2MTAwMDE2
# WjAnMSUwIwYDVQQDDBxQb3dlclNoZWxsIENvZGUgU2lnbmluZyBDZXJ0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3Pd5CH0+QX5u8/MAQB/iV2aVmpGh
# A4dMKmSbKKLV/zBt7B1AunWkwL0YeMQFRcle/qCmTQtpFnAP8VQuuzkZXWJoFcml
# PIyH6vPLpC8AD03QF5V9na0z6ArIJ3Y+u70lc9g/PJCYc3/BI4K8Se+ZQbLT5g+1
# AFgj7YOiRhjYOYa0NgAzctsVFlfKIRi0sLLNvAYMmhtlYLRndkd8kXuP3QnCkkfc
# qZYxx1GioDEOlC09VPoGWtK8glb0mVGoDrQhfE7dqbTESzBpbwgthWlDL8TPazWx
# ykWT2jkd7ptsv5oll3E00Q9YgT67VDH8JLZ8JM4JzIcYVXa3Zl9p9SiskQIDAQAB
# o0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0O
# BBYEFOXOD3HcTwOvRvbfwLWYPbNuQEBAMA0GCSqGSIb3DQEBCwUAA4IBAQCTHHCI
# wLwz2K/os/7RQCz8D81EeZCN8OxHkJVWdJLk3co2HuJFvHjoqEEohAN6uhw/mU+N
# 5IDE+R+XR6HT1RHFtfDKs4YR+qntz1Ue1UK1EVW5RIB+gVfKubeWL4L1N9uhmw/j
# jw0NvXSnrg5CK4wfXguc3gUtLXH8LM3Z4tFI+a3Cc3kwPc44Nm01lzbljObdt2GP
# Ecl+qarK6VB3IY5evc0Xt4xIqMLi5Q44/3mgMof+y4hWwzPcC/UkKsz+Qzy+lWxx
# eHx59OOvgxjom0qIKLLxgbsxLQRT1+yyhg8o58KV09Fm0z2HHzJVM3VA5a4FmwO6
# SiagdmozvxumzcstMYIB7TCCAekCAQEwOzAnMSUwIwYDVQQDDBxQb3dlclNoZWxs
# IENvZGUgU2lnbmluZyBDZXJ0AhBEklUIQAnQgkLGtOnc/LQFMA0GCWCGSAFlAwQC
# AQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
# hvcNAQkEMSIEIGVFjDwVps0LqBu0Fjx41sRMAjc6wkYyopeOFNFQ65KPMA0GCSqG
# SIb3DQEBAQUABIIBAB9La6GhBgE6kmbH2DCR7SzXIZykEF0/mkf5led3pWxfIhUz
# +u6m/5nakZoj94h+xiSwQDLhINGZ2e98V37IHi7uEAa0t7ES9zFG9LP5cDZhH6T6
# 8xYlV1322NsMLV48z8RRLYV+I2hDrthzAsHMYvNqe4YUKgl4zE5JmZXT1TmlyyhR
# 8fOX7W+f1ck4l39qhxtldPNE3nrfySUGpAtl9PX4ucFZXv2nH/QDCmAoshxCswNK
# QwNfyQRXm6HIpjNZOz/s4dYTr+uZa2G8iDHkPlJ/iuQjHo+ox+NtrZc4YL1ycUol
# hoRL4x/Ho0fTfqVTPhdKPYJy8IQzLWw9FDeUj+w=
# SIG # End signature block
