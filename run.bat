@echo off
setlocal
cd /d "%~dp0"

if exist "%ProgramFiles%\Git\git-bash.exe" (
    start "RetroOS" "%ProgramFiles%\Git\git-bash.exe" --cd="%~dp0." -c "bash retroos.sh"
) else if exist "%LOCALAPPDATA%\Programs\Git\git-bash.exe" (
    start "RetroOS" "%LOCALAPPDATA%\Programs\Git\git-bash.exe" --cd="%~dp0." -c "bash retroos.sh"
) else if exist "%ProgramFiles%\Git\bin\bash.exe" (
    start "RetroOS" "%ProgramFiles%\Git\bin\bash.exe" -c "cd \"%~dp0\" && bash retroos.sh"
) else (
    echo [ERROR] Git Bash was not found in default locations.
    echo Please install Git for Windows or run in WSL.
    pause
)
