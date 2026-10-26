#requires -version 5.1
<#
.SYNOPSIS
    Instalador do Baixador de Vídeos do YouTube.

.DESCRIPTION
    Copia o aplicativo para %LOCALAPPDATA%\Programas\BaixadorYouTube,
    instala as dependências (yt-dlp e ffmpeg), cria atalhos e registra
    o programa em "Aplicativos e recursos" para desinstalação.

.PARAMETER InstallDir
    Pasta de instalação. Padrão: %LOCALAPPDATA%\Programas\BaixadorYouTube

.PARAMETER SemAtalhos
    Não cria atalhos na Área de Trabalho nem no Menu Iniciar.

.PARAMETER NaoAbrir
    Não abre o programa ao final da instalação.
#>
[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Programas\BaixadorYouTube'),
    [switch]$SemAtalhos,
    [switch]$NaoAbrir
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

$AppName    = 'Baixador de Vídeos do YouTube'
$AppVersion = '1.1.0'
$AppId      = 'BaixadorYouTube'
$ExeName    = 'BaixadorYouTube.exe'
$Repo       = 'GutoPospichil/baixador-youtube'
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Desktop    = [Environment]::GetFolderPath('Desktop')
$StartMenu  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$UninstKey  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppId"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch { }

# ------------------------------------------------------------------ utilidades
function Write-Title([string]$Text) {
    Write-Host ''
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * [Math]::Max(10, $Text.Length + 4))) -ForegroundColor DarkCyan
}

function Write-Step([string]$Text) { Write-Host "  -> $Text" -ForegroundColor White }
function Write-Ok([string]$Text)   { Write-Host "     OK: $Text" -ForegroundColor Green }
function Write-Warn([string]$Text) { Write-Host "     AVISO: $Text" -ForegroundColor Yellow }
function Write-Err([string]$Text)  { Write-Host "     ERRO: $Text" -ForegroundColor Red }

function Test-Command([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-FileFromUrl([string]$Url, [string]$Destination) {
    Write-Step "Baixando $(Split-Path -Leaf $Destination)..."
    try {
        $client = New-Object System.Net.WebClient
        $client.Headers.Add('User-Agent', 'BaixadorYouTube-Installer')
        $client.DownloadFile($Url, $Destination)
        $client.Dispose()
    }
    catch {
        throw "Falha ao baixar $Url`n$($_.Exception.Message)"
    }
}

function Find-YtDlp {
    $candidates = @(
        (Join-Path $InstallDir 'yt-dlp.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\yt-dlp.exe'),
        (Join-Path $env:APPDATA 'Python\Scripts\yt-dlp.exe')
    )

    $cmd = Get-Command 'yt-dlp' -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { $candidates += $cmd.Source }

    $candidates += Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\yt-dlp*\yt-dlp.exe') `
                                 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    $candidates += Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python*\Scripts\yt-dlp.exe') `
                                 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) { return $path }
    }
    return $null
}

function Find-FFmpeg {
    $candidates = @(
        (Join-Path $InstallDir 'ffmpeg.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\ffmpeg.exe'),
        'C:\ffmpeg\bin\ffmpeg.exe'
    )

    $cmd = Get-Command 'ffmpeg' -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { $candidates += $cmd.Source }

    $candidates += Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Gyan.FFmpeg*\**\bin\ffmpeg.exe') `
                                 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) { return $path }
    }
    return $null
}

function Install-WingetPackage([string]$Id, [string]$Label) {
    if (-not (Test-Command 'winget')) { return $false }

    Write-Step "Instalando $Label via winget..."
    & winget install --id $Id -e --accept-source-agreements --accept-package-agreements --disable-interactivity 2>&1 | Out-Null
    $code = $LASTEXITCODE

    # 0 = sucesso | -1978335189 = já instalado
    if ($code -eq 0 -or $code -eq -1978335189) { return $true }
    return $false
}

function New-AppShortcut([string]$Path, [string]$Target) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $Target
    $shortcut.WorkingDirectory = Split-Path -Parent $Target
    $shortcut.IconLocation = "$Target,0"
    $shortcut.Description = $AppName
    $shortcut.Save()
}

# ------------------------------------------------------------------ instalacao
Clear-Host
$Host.UI.RawUI.WindowTitle = "Instalador - $AppName"

Write-Host ''
Write-Host '  ============================================================' -ForegroundColor DarkCyan
Write-Host "   $AppName" -ForegroundColor Cyan
Write-Host "   Instalador v$AppVersion" -ForegroundColor Gray
Write-Host '  ============================================================' -ForegroundColor DarkCyan
Write-Host ''
Write-Host "  Pasta de instalacao: $InstallDir" -ForegroundColor DarkGray

try {
    # 1. Pasta de instalacao
    Write-Title 'Preparando a instalacao'
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    Write-Ok 'Pasta de instalacao pronta'

    # 2. Aplicativo
    $targetExe = Join-Path $InstallDir $ExeName
    $localExe  = Join-Path $ScriptDir $ExeName
    if (-not (Test-Path $localExe)) {
        $distExe = Join-Path $ScriptDir "dist\$ExeName"
        if (Test-Path $distExe) { $localExe = $distExe }
    }

    if (Test-Path $localExe) {
        Copy-Item -Path $localExe -Destination $targetExe -Force
        Write-Ok 'Aplicativo copiado'
    }
    else {
        $url = "https://github.com/$Repo/releases/latest/download/$ExeName"
        Get-FileFromUrl -Url $url -Destination $targetExe
        Write-Ok 'Aplicativo baixado'
    }

    # 3. Dependencias
    Write-Title 'Verificando dependencias'

    $ytdlp = Find-YtDlp
    if ($ytdlp) {
        Write-Ok 'yt-dlp ja instalado'
    }
    else {
        if (Install-WingetPackage -Id 'yt-dlp.yt-dlp' -Label 'yt-dlp') {
            $ytdlp = Find-YtDlp
        }
        if (-not $ytdlp) {
            Write-Warn 'winget indisponivel, baixando yt-dlp.exe diretamente'
            $ytdlp = Join-Path $InstallDir 'yt-dlp.exe'
            Get-FileFromUrl -Url 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' -Destination $ytdlp
        }
        Write-Ok 'yt-dlp instalado'
    }

    $ffmpeg = Find-FFmpeg
    if ($ffmpeg) {
        Write-Ok 'ffmpeg ja instalado'
    }
    else {
        if (Install-WingetPackage -Id 'Gyan.FFmpeg' -Label 'ffmpeg') {
            $ffmpeg = Find-FFmpeg
        }
        if (-not $ffmpeg) {
            Write-Warn 'winget indisponivel, baixando ffmpeg diretamente (~100 MB)'
            $zipPath = Join-Path $env:TEMP 'ffmpeg-essentials.zip'
            $extract = Join-Path $env:TEMP 'ffmpeg-essentials'
            Get-FileFromUrl -Url 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -Destination $zipPath
            if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
            Expand-Archive -Path $zipPath -DestinationPath $extract -Force
            $ffmpegExe = Get-ChildItem -Path $extract -Filter 'ffmpeg.exe' -Recurse | Select-Object -First 1
            if (-not $ffmpegExe) { throw 'ffmpeg.exe nao encontrado no pacote baixado.' }
            Copy-Item $ffmpegExe.FullName (Join-Path $InstallDir 'ffmpeg.exe') -Force
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Ok 'ffmpeg instalado'
    }

    # 4. Desinstalador
    Write-Title 'Configurando desinstalacao'
    foreach ($file in @('Desinstalar.ps1', 'Desinstalar.bat')) {
        $source = Join-Path $ScriptDir $file
        if (Test-Path $source) {
            Copy-Item $source (Join-Path $InstallDir $file) -Force
        }
    }

    $uninstallScript = Join-Path $InstallDir 'Desinstalar.ps1'
    if (-not (Test-Path $uninstallScript)) {
        Get-FileFromUrl -Url "https://raw.githubusercontent.com/$Repo/main/Desinstalar.ps1" -Destination $uninstallScript
    }

    $uninstallCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$uninstallScript`""
    if (-not (Test-Path $UninstKey)) { New-Item -Path $UninstKey -Force | Out-Null }

    New-ItemProperty -Path $UninstKey -Name 'DisplayName'     -Value $AppName       -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'DisplayVersion'  -Value $AppVersion    -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'Publisher'       -Value 'Guto Pospichil' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'InstallLocation' -Value $InstallDir    -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'DisplayIcon'     -Value "$targetExe,0" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'UninstallString' -Value $uninstallCmd   -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'QuietUninstallString' -Value "$uninstallCmd -Silent" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'NoModify'        -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $UninstKey -Name 'NoRepair'        -Value 1 -PropertyType DWord -Force | Out-Null

    $size = (Get-ChildItem $InstallDir -Recurse -File | Measure-Object Length -Sum).Sum
    $sizeKb = [int]([Math]::Round($size / 1KB))
    New-ItemProperty -Path $UninstKey -Name 'EstimatedSize' -Value $sizeKb -PropertyType DWord -Force | Out-Null
    Write-Ok 'Registro de desinstalacao criado'

    # 5. Atalhos
    if (-not $SemAtalhos) {
        Write-Title 'Criando atalhos'
        New-AppShortcut -Path (Join-Path $Desktop "$AppName.lnk") -Target $targetExe
        Write-Ok 'Atalho na Area de Trabalho'
        New-AppShortcut -Path (Join-Path $StartMenu "$AppName.lnk") -Target $targetExe
        Write-Ok 'Atalho no Menu Iniciar'
    }

    # 6. Fim
    Write-Host ''
    Write-Host '  ============================================================' -ForegroundColor Green
    Write-Host '   Instalacao concluida com sucesso!' -ForegroundColor Green
    Write-Host '  ============================================================' -ForegroundColor Green
    Write-Host ''
    Write-Host '   Para desinstalar: Configuracoes > Aplicativos >' -ForegroundColor Gray
    Write-Host '   Aplicativos instalados > Baixador de Videos do YouTube' -ForegroundColor Gray
    Write-Host ''

    if (-not $NaoAbrir) {
        Read-Host '  Pressione ENTER para abrir o programa'
        Start-Process -FilePath $targetExe
    }
}
catch {
    Write-Host ''
    Write-Err $_.Exception.Message
    Write-Host ''
    Write-Host '  A instalacao nao foi concluida.' -ForegroundColor Red
    Read-Host '  Pressione ENTER para sair'
    exit 1
}
