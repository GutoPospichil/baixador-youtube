@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ===============================================
echo  Instalando yt-dlp e ffmpeg via winget...
echo ===============================================
echo.

where winget >nul 2>nul
if errorlevel 1 (
    echo [ERRO] O winget nao esta disponivel neste computador.
    echo.
    echo Baixe manualmente:
    echo   yt-dlp:  https://github.com/yt-dlp/yt-dlp/releases/latest
    echo   ffmpeg:  https://www.gyan.dev/ffmpeg/builds/
    echo Depois coloque yt-dlp.exe e ffmpeg.exe na mesma pasta deste arquivo.
    echo.
    pause
    exit /b 1
)

winget install --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements
winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements

echo.
echo Pronto! Agora abra o run.vbs para usar o programa.
echo.
pause
