# Drive the CHAR-BASE-T fix + review renders. Blender detaches, so every stage
# deletes its sentinel file first and then polls for it to come back.
param(
  [switch]$SkipFix,
  [switch]$SkipShots,
  [string]$Tag = "t-fix",
  [int]$Res = 768,
  [int]$Samples = 40,
  [string[]]$Set = @()
)

$ErrorActionPreference = "Stop"
$root = "C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2"
$bl = "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe"
$src = "$root\godot\immune\characters\base_t\CHAR-BASE-T-tripo-5k.glb"
$dst = "$root\godot\immune\characters\base_t\CHAR-BASE-T-fix.glb"
$rep = "$root\build\fix-report.json"
$shotDir = "$root\build\shots\$Tag"

function Wait-File($path, $timeout = 600) {
  for ($i = 0; $i -lt $timeout; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $path) {
      $a = (Get-Item $path).Length
      Start-Sleep -Milliseconds 900
      if ((Get-Item $path).Length -eq $a) { Write-Host "  -> $path after ${i}s"; return $true }
    }
  }
  Write-Host "  !! timeout waiting for $path"
  return $false
}

if (-not $SkipFix) {
  Write-Host "== fix =="
  if (Test-Path $rep) { Remove-Item $rep }
  $extra = @()
  foreach ($s in $Set) { $extra += @("--set", $s) }
  & $bl --background --factory-startup --python "$root\build\bl_fix_t.py" -- --glb $src --out $dst --report $rep @extra | Out-Null
  if (-not (Wait-File $rep)) { exit 1 }
  Get-Content $rep -Raw | Write-Host
}

if (-not $SkipShots) {
  Write-Host "== shots =="
  $done = "$shotDir\$Tag-report.json"
  if (Test-Path $done) { Remove-Item $done }
  & $bl --background --factory-startup --python "$root\build\bl_shots.py" -- --glb $dst --out $shotDir --tag $Tag --res $Res --samples $Samples --engine cycles | Out-Null
  if (-not (Wait-File $done)) { exit 1 }
  # the report lands first; the seven renders follow
  if (-not (Wait-File "$shotDir\$Tag-facehigh.png" 900)) { exit 1 }
  Write-Host "shots in $shotDir"
}
