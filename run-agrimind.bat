@echo off
setlocal EnableExtensions EnableDelayedExpansion
title AgriMind AI Launcher
color 0A
cd /d "%~dp0"

set "ROOT=%~dp0"
set "BACKEND=%ROOT%backend"
set "API_URL=http://127.0.0.1:8000"
set "VENV_PY=%BACKEND%\.venv\Scripts\python.exe"

echo.
echo  ============================================================
echo     AgriMind AI  -  Smart Irrigation, Smarter Farming
echo  ============================================================
echo.

if not exist "%BACKEND%\app\main.py" (
    echo  [ERROR] Cannot find backend\app\main.py
    echo          Keep this file in the AgriMind-AI project root folder.
    pause
    exit /b 1
)

REM ---------- find Python ----------
set "PY="
where py >nul 2>nul
if not errorlevel 1 set "PY=py"
if not defined PY (
    where python >nul 2>nul
    if not errorlevel 1 set "PY=python"
)
if not defined PY (
    echo  [ERROR] Python 3.11 or newer was not found.
    echo          Install it from https://www.python.org and tick "Add to PATH".
    pause
    exit /b 1
)

REM ---------- choose target ----------
echo   Where do you want to run the app?
echo.
echo     [1] Chrome browser        (recommended)
echo     [2] Windows desktop
echo     [3] Android emulator or connected phone
echo     [4] Backend only          (opens API docs)
echo.
set "CHOICE="
set /p "CHOICE=  Select 1-4 [default 1]: "
if not defined CHOICE set "CHOICE=1"
if "%CHOICE%"=="1" goto choice_ok
if "%CHOICE%"=="2" goto choice_ok
if "%CHOICE%"=="3" goto choice_ok
if "%CHOICE%"=="4" goto choice_ok
echo  [ERROR] Invalid choice: %CHOICE%
pause
exit /b 1
:choice_ok

REM ---------- check Flutter when needed ----------
if not "%CHOICE%"=="4" (
    where flutter >nul 2>nul
    if errorlevel 1 (
        echo.
        echo  [ERROR] Flutter was not found in PATH.
        echo          Install the Flutter SDK and add its bin folder to PATH.
        pause
        exit /b 1
    )
)

REM ---------- backend environment ----------
echo.
echo  [1/4] Preparing backend environment...
if not exist "%VENV_PY%" (
    echo        Creating virtual environment...
    %PY% -m venv "%BACKEND%\.venv"
    if errorlevel 1 (
        echo  [ERROR] Could not create the virtual environment.
        pause
        exit /b 1
    )
)

echo  [2/4] Installing backend dependencies...
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r "%BACKEND%\requirements.txt"
if errorlevel 1 (
    echo  [ERROR] Dependency installation failed. Check your internet connection.
    pause
    exit /b 1
)

if not exist "%BACKEND%\.env" (
    echo        Creating backend\.env with a new secret key...
    set "SECRET="
    for /f %%i in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')"') do set "SECRET=%%i"
    > "%BACKEND%\.env" (
        echo DATABASE_URL=sqlite:///./agrimind_dev.db
        echo SECRET_KEY=!SECRET!
        echo ACCESS_TOKEN_EXPIRE_MINUTES=10080
        echo CORS_ORIGINS=*
        echo TIMEZONE=Asia/Kolkata
    )
)

REM ---------- start backend ----------
echo  [3/4] Starting backend server...
curl -s -f -o nul %API_URL%/health >nul 2>nul
if not errorlevel 1 (
    echo        Backend is already running at %API_URL%
    goto backend_ready
)

start "AgriMind Backend (close this window to stop the API)" /D "%BACKEND%" cmd /k .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload

set /a TRIES=0
:wait_loop
curl -s -f -o nul %API_URL%/health >nul 2>nul
if not errorlevel 1 goto backend_ready
set /a TRIES+=1
if !TRIES! GEQ 45 (
    echo.
    echo  [ERROR] Backend did not become healthy in time.
    echo          Look at the "AgriMind Backend" window for the error message.
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait_loop

:backend_ready
echo        Backend is healthy: %API_URL%/docs

if "%CHOICE%"=="4" (
    start "" "%API_URL%/docs"
    echo.
    echo  Backend only mode. API docs opened in your browser.
    echo  Close the "AgriMind Backend" window when you want to stop it.
    pause
    exit /b 0
)

REM ---------- run Flutter ----------
echo  [4/4] Launching the Flutter app...
cd /d "%ROOT%"
call flutter pub get
if errorlevel 1 (
    echo  [ERROR] flutter pub get failed.
    pause
    exit /b 1
)

echo.
if "%CHOICE%"=="1" call flutter run -d chrome
if "%CHOICE%"=="2" call flutter run -d windows
if "%CHOICE%"=="3" call flutter run

echo.
echo  App closed. The backend is still running in its own window.
echo  Close that window to stop the API.
pause
endlocal
