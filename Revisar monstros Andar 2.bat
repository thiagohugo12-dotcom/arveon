@echo off
setlocal
set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.5.1-stable_win64.exe"
if defined ARVEON_GODOT set "GODOT_EXE=%ARVEON_GODOT%"
if not exist "%GODOT_EXE%" (
  echo Godot 4.5.1 nao encontrado. Defina ARVEON_GODOT com o caminho do executavel.
  pause
  exit /b 1
)
"%GODOT_EXE%" --path "%~dp0" --scene res://scenes/demos/floor2_monsters_preview.tscn
