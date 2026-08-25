# Clay/wireframe close-up of one feature. Same detach-and-poll dance as the
# main runner: blender-launcher returns immediately, so wait on the sentinel.
param(
  [string]$Tag = "look",
  [string]$Target = "",
  [string]$Glb = "",
  [double]$Dist = 0.30,
  [int]$Res = 700,
  [int]$Samples = 24,
  [double]$Power = 1.0
)

$ErrorActionPreference = "Stop"
$root = "C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2"
$bl = "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe"
if (-not $Glb) { $Glb = "$root\godot\immune\characters\base_t\CHAR-BASE-T-fix.glb" }
$out = "$root\build\shots\$Tag"
$done = "$out\$Tag.done"

if (Test-Path $done) { Remove-Item $done }
$argsList = @("--background", "--factory-startup", "--python", "$root\build\bl_fix_t_look.py",
  "--", "--glb", $Glb, "--out", $out, "--tag", $Tag,
  "--res", "$Res", "--samples", "$Samples", "--dist", "$Dist", "--power", "$Power")
if ($Target) { $argsList += @("--target", $Target) }
& $bl @argsList | Out-Null

for ($i = 0; $i -lt 900; $i++) {
  Start-Sleep -Seconds 1
  if (Test-Path $done) { Write-Host "  -> $done after ${i}s"; break }
}
if (-not (Test-Path $done)) { Write-Host "  !! timeout"; exit 1 }
Get-ChildItem $out -Filter *.png | Select-Object -ExpandProperty Name
