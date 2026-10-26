#requires -version 5.1
<#
.SYNOPSIS
    Desinstalador do Baixador de Vídeos do YouTube.

.DESCRIPTION
    Fecha o programa, remove atalhos, registro de desinstalação e a pasta
    de instalação. As dependências (yt-dlp e ffmpeg) são mantidas no sistema.
#>
param(
    [switch]$Silent
)

$ErrorActionPreference = 'SilentlyContinue'

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

$AppName    = 'Baixador de Vídeos do YouTube'
$AppId      = 'BaixadorYouTube'
$InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Desktop    = [Environment]::GetFolderPath('Desktop')
$StartMenu  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$UninstKey  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppId"

if (-not $Silent) {
    Write-Host ''
    Write-Host "  Remover o $AppName?" -ForegroundColor Yellow
    $answer = Read-Host '  Digite S para confirmar'
    if ($answer -notmatch '^[sSyY]') {
        Write-Host '  Cancelado.' -ForegroundColor Gray
        Start-Sleep -Seconds 1
        exit 0
    }
    Write-Host ''
}

Write-Host '  Fechando o programa...'
Get-Process -Name 'BaixadorYouTube' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800

Write-Host '  Removendo atalhos...'
Remove-Item (Join-Path $Desktop "$AppName.lnk") -Force
Remove-Item (Join-Path $StartMenu "$AppName.lnk") -Force
Remove-Item (Join-Path $StartMenu 'Baixador de Videos do YouTube.lnk') -Force

Write-Host '  Removendo registro de desinstalacao...'
Remove-Item $UninstKey -Recurse -Force

Write-Host '  Removendo arquivos...'
cmd /c "timeout /t 1 /nobreak >nul & rmdir /s /q `"$InstallDir`"" | Out-Null

if (Test-Path $InstallDir) {
    Write-Host '  Nao foi possivel remover todos os arquivos.' -ForegroundColor Yellow
    Write-Host "  Remova manualmente a pasta: $InstallDir"
}
else {
    Write-Host '  Programa removido com sucesso!' -ForegroundColor Green
}

Write-Host ''
Write-Host '  Obs.: yt-dlp e ffmpeg NAO foram removidos.' -ForegroundColor DarkGray
Write-Host '  Eles podem ser usados por outros programas.' -ForegroundColor DarkGray
Write-Host ''

if (-not $Silent) {
    Read-Host '  Pressione ENTER para sair'
}
