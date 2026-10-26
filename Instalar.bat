@echo off
chcp 65001 >nul
title Instalador - Baixador de Videos do YouTube
setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar.ps1"
if errorlevel 1 (
    echo.
    echo A instalacao falhou. Veja as mensagens acima.
    pause
    exit /b 1
)
exit /b 0
