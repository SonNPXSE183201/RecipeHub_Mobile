# Build APK RecipeHub Mobile (chạy trên máy có Flutter 3.47.2 + Android SDK).
#   .\tools\build_apk.ps1                 # release APK
#   .\tools\build_apk.ps1 -Debug          # debug APK
#   .\tools\build_apk.ps1 -SkipChecks     # bỏ qua flutter analyze/test
# Cần android\app\google-services.json (không commit). Nếu thiếu, script lấy từ $KeySource.
param(
  [switch]$Debug,
  [switch]$SkipChecks,
  [string]$KeySource = 'D:\PRM393\RecipeHub_Mobile'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$gs = Join-Path $root 'android\app\google-services.json'
if (-not (Test-Path $gs)) {
  $src = Join-Path $KeySource 'android\app\google-services.json'
  if (-not (Test-Path $src)) { throw "Thiếu google-services.json (không thấy ở $src)" }
  Copy-Item $src $gs
  Write-Host "Đã chép google-services.json từ $KeySource"
}

# GOOGLE_SERVER_CLIENT_ID = OAuth client loại Web (client_type 3) trong google-services.json
$json = Get-Content $gs -Raw | ConvertFrom-Json
$webId = $json.client.oauth_client | Where-Object { $_.client_type -eq 3 } | Select-Object -First 1 -ExpandProperty client_id
if (-not $webId) { throw 'Không tìm thấy Web OAuth client (client_type 3) trong google-services.json' }

flutter pub get
if (-not $SkipChecks) {
  flutter analyze --no-pub
  flutter test --no-pub
}

$mode = if ($Debug) { '--debug' } else { '--release' }
flutter build apk $mode --dart-define=GOOGLE_SERVER_CLIENT_ID="$webId"

$kind = if ($Debug) { 'debug' } else { 'release' }
$apk = Join-Path $root "build\app\outputs\flutter-apk\app-$kind.apk"
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$out = Join-Path $dist ("RecipeHub_{0}_{1}.apk" -f $kind, (Get-Date -Format 'yyyyMMdd_HHmm'))
Copy-Item $apk $out
Write-Host "APK: $out"
