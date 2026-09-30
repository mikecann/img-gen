$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\install-lib.ps1")

function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}

# Check the real ICO conversion without Windows graphics libraries.
$ico = [System.IO.Path]::GetTempFileName()
try {
    $pngPath = Join-Path $PSScriptRoot "..\icons\img-gen.png"
    ConvertTo-Ico $pngPath $ico
    $bytes = [System.IO.File]::ReadAllBytes($ico)
    $png = [System.IO.File]::ReadAllBytes($pngPath)
    Assert ([BitConverter]::ToUInt16($bytes, 2) -eq 1) "ICO must be an icon"
    Assert ([BitConverter]::ToUInt16($bytes, 4) -eq 1) "ICO must contain one image"
    Assert ([BitConverter]::ToUInt32($bytes, 14) -eq $png.Length) "Wrong PNG length"
    Assert ([BitConverter]::ToUInt32($bytes, 18) -eq 22) "Wrong PNG offset"
    Assert ([Convert]::ToBase64String($bytes[22..($bytes.Length - 1)]) -eq [Convert]::ToBase64String($png)) "PNG bytes changed"
} finally {
    Remove-Item -LiteralPath $ico -Force
}

# Model registry operations so the shared-menu contract is testable on macOS too.
$script:registry = @{}
function Test-Path($LiteralPath) { return $script:registry.ContainsKey($LiteralPath) }
function New-Item($Path, [switch]$Force) {
    if (-not $script:registry.ContainsKey($Path)) { $script:registry[$Path] = @{} }
}
function Set-ItemProperty($LiteralPath, $Name, $Value) { $script:registry[$LiteralPath][$Name] = $Value }
function Remove-Item($LiteralPath, [switch]$Recurse, [switch]$Force) {
    foreach ($key in @($script:registry.Keys)) {
        if ($key -eq $LiteralPath -or $key.StartsWith("$LiteralPath\")) { $script:registry.Remove($key) }
    }
}

foreach ($root in @("FolderMenu", "FolderBackgroundMenu")) {
    Set-MikesToolsRoot $root
    Assert ($script:registry[$root]["MUIVerb"] -eq "Mike's Tools") "Missing shared menu label"
    Assert ($script:registry[$root]["SubCommands"] -eq "") "Missing nested menu setup"
    $script:registry[$root]["Icon"] = "another-tools-icon"
    $otherVerb = "$root\shell\OtherTool"
    $script:registry[$otherVerb] = @{ MUIVerb = "Other tool" }

    Set-MikesToolsRoot $root
    Add-MikesVerb $root "ImgGen" "Image Gen" "img-gen.ico" 'wscript.exe "C:\clone with spaces\img-gen.vbs" "%1"'
    Assert ($script:registry[$root]["Icon"] -eq "another-tools-icon") "Existing root icon was overwritten"
    Assert ($script:registry["$root\shell\ImgGen"]["MUIVerb"] -eq "Image Gen") "Missing Image Gen label"
    Assert ($script:registry["$root\shell\ImgGen\command"]["(Default)"] -like '*"C:\clone with spaces\img-gen.vbs"*') "Command lost launcher quoting"

    Remove-ImgGenVerb $root
    Remove-ImgGenVerb $root
    Assert (-not $script:registry.ContainsKey("$root\shell\ImgGen")) "ImgGen was not removed"
    Assert (-not $script:registry.ContainsKey("$root\shell\ImgGen\command")) "ImgGen command was not removed"
    Assert ($script:registry.ContainsKey($root)) "Shared root was removed"
    Assert ($script:registry.ContainsKey($otherVerb)) "Other tool was removed"
}
Write-Host "Installer helper checks passed."
