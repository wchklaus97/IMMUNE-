# Sequential uniform sweep for the wet-gel material.
#
# Godot needs a real window to produce pixels (--headless renders nothing) and a
# second instance will fight the first for it, so these runs are strictly serial
# with a kill between each. Each config renders into its own folder and the front
# view is then measured with gel_compare.py --zones.
#
# Usage:
#   .\build\gel_sweep.ps1 -Tag probe -Sets @('albedo_gain:3.0,body_budget:8.0','albedo_gain:3.0,body_budget:2.5')
param(
    [Parameter(Mandatory = $true)][string]$Tag,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Sets,
    [string]$Family = 'T',
    [switch]$NoMeasure
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = 'C:\Users\wchkl\AppData\Local\Microsoft\WinGet\Links\godot_console.exe'
$ref = Join-Path $root 'godot\immune\characters\concepts\CHAR-BASE-T-3d-alt.png'
$outs = @()

for ($i = 0; $i -lt $Sets.Count; $i++) {
    $set = $Sets[$i]
    $name = "$Tag-$i"
    $out = Join-Path $root "build\shots\$name"
    Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 400
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }

    $tail = @(
        '--scene=res://tools/gel_preview.tscn',
        "--out=$out",
        "--tag=$name",
        "--family=$Family"
    )
    if ($set -ne '') { $tail += "--set=$set" }

    Write-Host "[$name] $set"
    & $exe --path (Join-Path $root 'godot\immune') --resolution 1024x1024 --position 60,60 `
        'res://tools/shot.tscn' -- @tail 2>&1 |
        Select-String -Pattern 'ERROR|SHADER|GEL_PREVIEW' | ForEach-Object { "  $_" }

    # The harness writes asynchronously; give the file a moment to land.
    $front = Join-Path $out "$name-front.png"
    for ($w = 0; $w -lt 20 -and -not (Test-Path $front); $w++) { Start-Sleep -Milliseconds 500 }
    if (Test-Path $front) { $outs += $front } else { Write-Host "  MISSING $front" }
}

Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
if (-not $NoMeasure -and $outs.Count -gt 0) {
    python (Join-Path $root 'build\gel_compare.py') --zones $ref @outs
}
