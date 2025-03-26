$packages = @(
    "7zip.7zip",
    "9NKSQGP7F2NH", # WhatsApp
    "Docker.DockerDesktop",
    "Figma.Figma", "Figma.FigmaAgent",
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.PowerToys",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    "Microsoft.VisualStudioCode",
    "Microsoft.WindowsTerminal",
    "Microsoft.WSL",
    "PostgreSQL.PostgreSQL.17",
    "RustDesk.RustDesk",
    "Telegram.TelegramDesktop"
)

if (!((Get-Command winget -ErrorAction SilentlyContinue))) {
    Write-Warning "WinGet not installed. Please install it first."
    exit
}

function Install-PackageIfNotInstalled($PackageName) {
    if ((winget list --exact --id $PackageName).Count -eq 0) {
        Write-Host "Installing package: $PackageName"
        winget install --exact --id $PackageName | Out-Null
    }
    else {
        Write-Host "$PackageName is already installed."
    }
}

foreach ($package in $packages) {
    Start-Job -ScriptBlock { param($pkg) Install-PackageIfNotInstalled $pkg } -ArgumentList $package
}

while ((Get-Job -State Running).Count -gt 0) {
    Start-Sleep -Milliseconds 100
}

Get-Job | Receive-Job

# WSL
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction SilentlyContinue
wsl --update; wsl --install Ubuntu

# Rust
Invoke-WebRequest -Uri 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile 'rust-installer.exe'
Start-Process -Wait -FilePath .\rust-installer.exe -ArgumentList '-y'
Remove-Item -Path .\rust-installer.exe -Force -ErrorAction SilentlyContinue

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
