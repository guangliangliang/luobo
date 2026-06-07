param(
    [string]$MonstersRoot = "",
    [switch]$NoOverwrite,
    [int]$TransparentPadding = 18,
    [int]$AlphaThreshold = 8
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrWhiteSpace($MonstersRoot)) {
    $ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $MonstersRoot = Join-Path $ProjectRoot "assets\monsters"
}

$MonstersRoot = (Resolve-Path $MonstersRoot).Path

function New-ArgbBitmapFromFile {
    param([string]$Path)

    $source = [System.Drawing.Image]::FromFile($Path)
    try {
        $bitmap = New-Object System.Drawing.Bitmap $source.Width, $source.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.DrawImage($source, 0, 0, $source.Width, $source.Height)
        }
        finally {
            $graphics.Dispose()
        }
        return $bitmap
    }
    finally {
        $source.Dispose()
    }
}

function Get-ContentBounds {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$AlphaThreshold
    )

    $minX = $Bitmap.Width
    $minY = $Bitmap.Height
    $maxX = -1
    $maxY = -1

    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            $pixel = $Bitmap.GetPixel($x, $y)
            if ($pixel.A -gt $AlphaThreshold) {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($maxX -lt 0 -or $maxY -lt 0) {
        return New-Object System.Drawing.Rectangle 0, 0, $Bitmap.Width, $Bitmap.Height
    }

    return New-Object System.Drawing.Rectangle $minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1)
}

function Copy-BitmapRegion {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [System.Drawing.Rectangle]$Region
    )

    $output = New-Object System.Drawing.Bitmap $Region.Width, $Region.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.DrawImage($Bitmap, (New-Object System.Drawing.Rectangle 0, 0, $Region.Width, $Region.Height), $Region, [System.Drawing.GraphicsUnit]::Pixel)
    }
    finally {
        $graphics.Dispose()
    }
    return $output
}

function Expand-Rectangle {
    param(
        [System.Drawing.Rectangle]$Rect,
        [int]$Padding,
        [int]$MaxWidth,
        [int]$MaxHeight
    )

    $x = [Math]::Max(0, $Rect.X - $Padding)
    $y = [Math]::Max(0, $Rect.Y - $Padding)
    $right = [Math]::Min($MaxWidth, $Rect.Right + $Padding)
    $bottom = [Math]::Min($MaxHeight, $Rect.Bottom + $Padding)
    return New-Object System.Drawing.Rectangle $x, $y, ($right - $x), ($bottom - $y)
}

$monsterDirs = Get-ChildItem -LiteralPath $MonstersRoot -Directory | Sort-Object Name

foreach ($dir in $monsterDirs) {
    $type = $dir.Name
    $iconPath = Join-Path $dir.FullName "$type`_icon.png"
    if ($NoOverwrite -and (Test-Path -LiteralPath $iconPath)) {
        Write-Host "skip existing icon: $type"
        continue
    }

    $sheetPath = Join-Path $dir.FullName "$type`_sheet.png"
    $walkPath = Join-Path $dir.FullName "$type`_walk_01.png"

    $sourcePath = ""
    $sourceKind = ""
    if (Test-Path -LiteralPath $sheetPath) {
        $sourcePath = $sheetPath
        $sourceKind = "sheet"
    }
    elseif (Test-Path -LiteralPath $walkPath) {
        $sourcePath = $walkPath
        $sourceKind = "walk_01"
    }
    else {
        Write-Host "skip missing source: $type"
        continue
    }

    $bitmap = New-ArgbBitmapFromFile $sourcePath
    try {
        if ($sourceKind -eq "sheet") {
            $frameWidth = [Math]::Floor($bitmap.Width / 4)
            $frameRegion = New-Object System.Drawing.Rectangle 0, 0, $frameWidth, $bitmap.Height
            $firstFrame = Copy-BitmapRegion $bitmap $frameRegion
        }
        else {
            $firstFrame = $bitmap.Clone()
        }

        try {
            $bounds = Get-ContentBounds $firstFrame $AlphaThreshold
            $bounds = Expand-Rectangle $bounds $TransparentPadding $firstFrame.Width $firstFrame.Height
            $icon = Copy-BitmapRegion $firstFrame $bounds
            try {
                $icon.Save($iconPath, [System.Drawing.Imaging.ImageFormat]::Png)
                Write-Host "wrote $type -> $iconPath ($sourceKind)"
            }
            finally {
                $icon.Dispose()
            }
        }
        finally {
            $firstFrame.Dispose()
        }
    }
    finally {
        $bitmap.Dispose()
    }
}
