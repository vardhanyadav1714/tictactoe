$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    if (!(Test-Path -LiteralPath 'tictactoe.jks') -or !(Test-Path -LiteralPath 'android/tictactoe.properties')) {
        throw 'Restore tictactoe.jks and android/tictactoe.properties first. See docs/signing.md.'
    }
    & flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { throw 'App bundle build failed.' }
    & flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
    New-Item -ItemType Directory -Force 'build/distributions' | Out-Null
    Copy-Item -LiteralPath 'build/app/outputs/bundle/release/app-release.aab' -Destination 'build/distributions/tictactoe.aab'
    Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' -Destination 'build/distributions/tictactoe.apk'
    Write-Output 'Signed files: build/distributions/tictactoe.aab and build/distributions/tictactoe.apk'
} finally {
    Pop-Location
}
