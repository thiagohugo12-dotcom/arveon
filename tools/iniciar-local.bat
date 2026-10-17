@echo off
setlocal
title ARVEON - Local
for %%I in ("%~dp0..") do set "ARVEON_PROJECT=%%~fI"
if not defined ARVEON_GODOT set "ARVEON_GODOT=%USERPROFILE%\Downloads\Godot_v4.5.1-stable_win64_console.exe"
if not exist "%ARVEON_GODOT%" (
    echo Godot 4.5.1 nao encontrado em:
    echo %ARVEON_GODOT%
    echo Configure ARVEON_GODOT com o caminho do executavel do Godot.
    pause
    exit /b 1
)
cd /d "%ARVEON_PROJECT%"
if not exist "%ARVEON_PROJECT%\.godot\global_script_class_cache.cfg" (
    echo Preparando o projeto na primeira abertura...
    "%ARVEON_GODOT%" --headless --path "%ARVEON_PROJECT%" --editor --import
    if errorlevel 1 exit /b 1
)
"%ARVEON_GODOT%" --path "%ARVEON_PROJECT%" --rendering-method gl_compatibility --rendering-driver opengl3 %*
set "ARVEON_EXIT=%ERRORLEVEL%"
if not "%ARVEON_EXIT%"=="0" (
    echo O Godot encerrou com erro %ARVEON_EXIT%.
    pause
)
exit /b %ARVEON_EXIT%
