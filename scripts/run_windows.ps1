$ErrorActionPreference = "Stop"

$envFile = ".\.env.local"
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*\$env:([A-Z0-9_]+)\s*=\s*"([^"]*)"') {
      $name = $matches[1]
      $value = $matches[2]
      Set-Item -Path "Env:$name" -Value $value
    }
  }
}

if (-not $env:GITHUB_OAUTH_CLIENT_ID) {
  Write-Error "GITHUB_OAUTH_CLIENT_ID is required. Set it in .env.local."
  exit 1
}

flutter run -d windows `
  --dart-define=GITHUB_OAUTH_CLIENT_ID="$env:GITHUB_OAUTH_CLIENT_ID" `
  -v
