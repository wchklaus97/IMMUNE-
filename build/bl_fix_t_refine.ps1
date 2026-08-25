# Try one refinement layout: rebuild, dump the subdivided mesh, print the count.
# The pore's rim quality is set by how dense the *skull* is where the sunk lens
# crosses it, and that is cheap or expensive depending entirely on the shape of
# the region, so it is worth measuring rather than guessing.
param([Parameter(Mandatory = $true)][string]$Refine)

$ErrorActionPreference = "Stop"
$root = "C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2"
$bl = "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe"
$rep = "$root\build\dump-report.json"

if (Test-Path $rep) { Remove-Item $rep }
& $bl --background --factory-startup --python "$root\build\bl_fix_t.py" -- `
  --glb "$root\godot\immune\characters\base_t\CHAR-BASE-T-tripo-5k.glb" `
  --out "$root\build\dump-tmp.glb" --report $rep --dump "$root\build\dump" `
  --refine $Refine | Out-Null
for ($i = 0; $i -lt 300; $i++) {
  Start-Sleep -Seconds 1
  if (Test-Path $rep) { Start-Sleep -Milliseconds 800; break }
}
(Get-Content $rep -Raw | ConvertFrom-Json).tris
