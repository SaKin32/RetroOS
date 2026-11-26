@echo off
setlocal
if exist "%ProgramFiles%\Git\bin\bash.exe" (
    "%ProgramFiles%\Git\bin\bash.exe" "%~dp0retroos.sh"
) else if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" (
    "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" "%~dp0retroos.sh"
) else (
    echo [ERROR] Git Bash was not found in default locations.
    echo Please run this in WSL (Windows Subsystem for Linux) or install Git Bash.
    pause
)
