@echo off
chcp 65001 >nul
title Desinstalar - Baixador de Videos do YouTube
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desinstalar.ps1"
if errorlevel 1 pause
exit /b 0
