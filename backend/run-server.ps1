Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

if (-not (Test-Path ".env")) {
    @"
DATABASE_URL=sqlite:///./agrimind_dev.db
SECRET_KEY=replace-with-a-long-random-local-string
CORS_ORIGINS=*
TIMEZONE=Asia/Kolkata
"@ | Set-Content -Encoding ascii ".env"
}

py -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
