$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot

# Draw original vector geometry at 4x resolution, then downsample for crisp icons.
function Write-GridlyIcon([string]$relativePath, [int]$size) {
    $canvasSize = $size * 4
    $bitmap = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#0C101B'))
    $graphics.ScaleTransform($canvasSize / 100.0, $canvasSize / 100.0)
    $grid = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#293447'), 2)
    $mint = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#9EF1CF'), 6)
    $coral = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#FFAE9A'), 6)
    foreach ($pen in @($grid, $mint, $coral)) {
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    }
    $graphics.DrawLine($grid, 50, 22, 50, 78)
    $graphics.DrawLine($grid, 22, 50, 78, 50)
    $graphics.DrawLine($mint, 25, 25, 39, 39)
    $graphics.DrawLine($mint, 39, 25, 25, 39)
    $graphics.DrawEllipse($coral, 59, 59, 17, 17)
    $result = New-Object System.Drawing.Bitmap($size, $size)
    $outputGraphics = [System.Drawing.Graphics]::FromImage($result)
    $outputGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $outputGraphics.DrawImage($bitmap, 0, 0, $size, $size)
    $targetPath = Join-Path $projectRoot $relativePath
    $result.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $outputGraphics.Dispose()
    $result.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
    foreach ($pen in @($grid, $mint, $coral)) { $pen.Dispose() }
}

foreach ($entry in @(@('mdpi', 48), @('hdpi', 72), @('xhdpi', 96), @('xxhdpi', 144), @('xxxhdpi', 192))) {
    Write-GridlyIcon "android/app/src/main/res/mipmap-$($entry[0])/ic_launcher.png" $entry[1]
}
$iosContents = Get-Content -Raw (Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') | ConvertFrom-Json
foreach ($icon in $iosContents.images) {
    $size = [int]([double]($icon.size.Split('x')[0]) * [int]($icon.scale.Replace('x', '')))
    Write-GridlyIcon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($icon.filename)" $size
}
foreach ($size in @(192, 512)) {
    Write-GridlyIcon "web/icons/Icon-$size.png" $size
    Write-GridlyIcon "web/icons/Icon-maskable-$size.png" $size
}
Write-GridlyIcon 'web/favicon.png' 48
Write-GridlyIcon 'branding/gridly-icon.png' 1024
Write-Output 'Generated Gridly icons for Android, iOS, and web.'
