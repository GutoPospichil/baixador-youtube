@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ===============================================
echo  Gerando executavel com PyInstaller...
echo ===============================================
echo.

python -m pip install --upgrade pyinstaller
if errorlevel 1 goto :erro

python -m PyInstaller --noconfirm --clean --onefile --windowed --name "BaixadorYouTube" app.py
if errorlevel 1 goto :erro

echo.
echo Executavel criado em: %~dp0dist\BaixadorYouTube.exe
echo.
pause
exit /b 0

:erro
echo.
echo [ERRO] Falha ao gerar o executavel. Verifique se o Python esta instalado.
echo.
pause
exit /b 1
