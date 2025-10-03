:: This method is not recommended, and we recommend you use the `start.sh` file with WSL instead.
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Get the directory of the current script
SET "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%" || exit /b

:: If a virtual environment exists in the project root .venv, activate it so python/uvicorn come from the venv
IF EXIST "%SCRIPT_DIR%..\.venv\Scripts\activate.bat" (
    echo Activating virtual environment at ..\..\.venv
    call "%SCRIPT_DIR%..\.venv\Scripts\activate.bat"
)

:: Add conditional Playwright browser installation
IF /I "%WEB_LOADER_ENGINE%" == "playwright" (
    IF "%PLAYWRIGHT_WS_URL%" == "" (
        echo Installing Playwright browsers...
        playwright install chromium
        playwright install-deps chromium
    )

    python -c "import nltk; nltk.download('punkt_tab')"
)

SET "KEY_FILE=.webui_secret_key"
IF NOT "%WEBUI_SECRET_KEY_FILE%" == "" (
    SET "KEY_FILE=%WEBUI_SECRET_KEY_FILE%"
)

IF "%PORT%"=="" SET PORT=8080
IF "%HOST%"=="" SET HOST=0.0.0.0
SET "WEBUI_SECRET_KEY=%WEBUI_SECRET_KEY%"
SET "WEBUI_JWT_SECRET_KEY=%WEBUI_JWT_SECRET_KEY%"

:: Ensure CORS and WEBUI_URL are set for local development so the frontend can connect
IF "%CORS_ALLOW_ORIGIN%"=="" (
    REM Allow the frontend dev server and backend itself
    SET CORS_ALLOW_ORIGIN=http://localhost:5173;http://localhost:8080
    echo Setting CORS_ALLOW_ORIGIN=%CORS_ALLOW_ORIGIN%
)

IF "%WEBUI_URL%"=="" (
    REM Use localhost for frontend/backlink; avoid 0.0.0.0 in URLs
    SET WEBUI_URL=http://localhost:%PORT%
    echo Setting WEBUI_URL=%WEBUI_URL%
)

:: Make Python output unbuffered so logs appear immediately
SET PYTHONUNBUFFERED=1

:: Check if WEBUI_SECRET_KEY and WEBUI_JWT_SECRET_KEY are not set
IF "%WEBUI_SECRET_KEY% %WEBUI_JWT_SECRET_KEY%" == " " (
    echo Loading WEBUI_SECRET_KEY from file, not provided as an environment variable.

    IF NOT EXIST "%KEY_FILE%" (
        echo Generating WEBUI_SECRET_KEY
        :: Use Python to generate a base64-encoded random secret and save it to the key file
        python -c "import base64,os; open(r'%KEY_FILE%','w').write(base64.b64encode(os.urandom(12)).decode())"
        echo WEBUI_SECRET_KEY generated and saved to %KEY_FILE%
    )

    echo Loading WEBUI_SECRET_KEY from %KEY_FILE%
    SET /p WEBUI_SECRET_KEY=<%KEY_FILE%
)

:: Execute uvicorn using the environment's python so the venv's uvicorn is preferred when available
SET "WEBUI_SECRET_KEY=%WEBUI_SECRET_KEY%"
IF "%UVICORN_WORKERS%"=="" SET UVICORN_WORKERS=1
python -m uvicorn open_webui.main:app --host "%HOST%" --port "%PORT%" --forwarded-allow-ips '*' --workers %UVICORN_WORKERS% --ws auto
:: For ssl user uvicorn open_webui.main:app --host "%HOST%" --port "%PORT%" --forwarded-allow-ips '*' --ssl-keyfile "key.pem" --ssl-certfile "cert.pem" --ws auto
