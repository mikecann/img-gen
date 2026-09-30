# Remove only img-gen's Explorer entries and its generated icon.
$ErrorActionPreference = "Stop"
if ($env:OS -ne "Windows_NT") { throw "Run uninstall.ps1 on Windows." }
. (Join-Path $PSScriptRoot "install-lib.ps1")

Remove-ImgGenVerb "HKCU:\Software\Classes\Directory\shell\MikesTools"
Remove-ImgGenVerb "HKCU:\Software\Classes\Directory\Background\shell\MikesTools"
$icon = Join-Path $env:LOCALAPPDATA "img-gen\icons\img-gen.ico"
if (Test-Path -LiteralPath $icon) { Remove-Item -LiteralPath $icon -Force }
Write-Host "Removed img-gen's Explorer entries. The shared Mike's Tools submenu is kept." -ForegroundColor Green
