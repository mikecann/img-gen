# Register img-gen on folder items and folder backgrounds in File Explorer.
param([switch]$SkipDeps)

$ErrorActionPreference = "Stop"
if ($env:OS -ne "Windows_NT") { throw "Run install.ps1 on Windows. On macOS use install.sh." }
. (Join-Path $PSScriptRoot "install-lib.ps1")

if (-not $SkipDeps) { & (Join-Path $PSScriptRoot "deps.ps1") }

$iconsOut = Join-Path $env:LOCALAPPDATA "img-gen\icons"
New-Item -ItemType Directory -Path $iconsOut -Force | Out-Null
$icon = Join-Path $iconsOut "img-gen.ico"
ConvertTo-Ico (Join-Path $PSScriptRoot "icons\img-gen.png") $icon

$launcher = Join-Path $PSScriptRoot "img-gen.vbs"
$dirRoot = "HKCU:\Software\Classes\Directory\shell\MikesTools"
$bgRoot = "HKCU:\Software\Classes\Directory\Background\shell\MikesTools"
Set-MikesToolsRoot $dirRoot
Add-MikesVerb $dirRoot "ImgGen" "Image Gen" $icon "wscript.exe `"$launcher`" `"%1`""
Set-MikesToolsRoot $bgRoot
Add-MikesVerb $bgRoot "ImgGen" "Image Gen" $icon "wscript.exe `"$launcher`" `"%V`""

Write-Host "Installed img-gen. Right-click a folder, then Mike's Tools > Image Gen." -ForegroundColor Green
Write-Host "On Windows 11, choose Show more options first." -ForegroundColor Yellow
