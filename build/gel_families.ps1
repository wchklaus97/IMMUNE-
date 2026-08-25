# Render all six base-cell families with the gel material and montage them, so a
# palette-derivation change can be checked for family separability in one look.
param([string]$Tag = 'fam')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = 'C:\Users\wchkl\AppData\Local\Microsoft\WinGet\Links\godot_console.exe'
$fronts = @()

foreach ($f in @('T', 'B', 'M', 'N', 'A', 'D')) {
    $name = "$Tag-$f"
    $out = Join-Path $root "build\shots\$name"
    Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 400
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    Write-Host "[$name]"
    & $exe --path (Join-Path $root 'godot\immune') --resolution 1024x1024 --position 60,60 `
        'res://tools/shot.tscn' -- '--scene=res://tools/gel_preview.tscn' `
        "--out=$out" "--tag=$name" "--family=$f" 2>&1 |
        Select-String -Pattern 'ERROR|SHADER' | ForEach-Object { "  $_" }
    $front = Join-Path $out "$name-front.png"
    for ($w = 0; $w -lt 20 -and -not (Test-Path $front); $w++) { Start-Sleep -Milliseconds 500 }
    if (Test-Path $front) { $fronts += $front } else { Write-Host "  MISSING $front" }
}

Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
$montage = Join-Path $root "build\shots\$Tag-sheet.png"
python (Join-Path $root 'build\gel_compare.py') --montage $montage @fronts
Write-Host "sheet: $montage"
