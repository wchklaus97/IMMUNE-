# Renders every gel animation through the shared review harness and builds a
# labelled contact sheet per clip.
#
#   pwsh build/render_anims.ps1 [-Tag t-anim] [-Body mesh] [-Frames 12] [-Anims idle,hit]

param(
  [string]$Tag = "t-anim",
  [string]$Body = "mesh",
  [int]$Frames = 12,
  [string[]]$Anims = @("idle", "plant", "uproot", "move", "hit", "attack"),
  [string]$Kits = "0",
  [string]$Family = "T"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$proj = Join-Path $root "godot\immune"
$out = Join-Path $root "build\shots\$Tag"
$godot = "C:\Users\wchkl\AppData\Local\Microsoft\WinGet\Links\godot_console.exe"

foreach ($anim in $Anims) {
  Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Milliseconds 250
  & $godot --path $proj --resolution 1024x1024 --position 60,60 "res://tools/shot.tscn" -- `
    "--scene=res://tools/anim_preview.tscn" "--out=$out" "--tag=$Tag" `
    "--anim=$anim" "--frames=$Frames" "--body=$Body" "--kits=$Kits" "--family=$Family" 2>&1 |
    Where-Object { $_ -match "ERROR|SCRIPT|error|Cannot|Invalid" }
  python (Join-Path $root "build\anim_sheet.py") $out $Tag $anim 6 300
}

Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Output "done -> $out"
