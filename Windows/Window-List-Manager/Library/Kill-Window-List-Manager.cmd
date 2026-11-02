@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Kill-Window-List-Manager.ps1" %*
if errorlevel 1 (
    echo.
    echo Some instances could not be stopped. Try running this CMD file as administrator.
    pause
) else (
    timeout /t 3 /nobreak >nul
)
endlocal
