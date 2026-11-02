@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-EXE.ps1"
if errorlevel 1 pause
