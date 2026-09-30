# Embed the existing 16px PNG in an ICO, preserving its alpha channel.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey) {
    # Other standalone tools share this submenu. Leave its existing settings alone.
    if (-not (Test-Path -LiteralPath $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $rootKey -Name "MUIVerb" -Value "Mike's Tools"
        Set-ItemProperty -LiteralPath $rootKey -Name "SubCommands" -Value ""
        # A system icon survives uninstalling whichever tool created the submenu.
        Set-ItemProperty -LiteralPath $rootKey -Name "Icon" -Value "$env:SystemRoot\System32\shell32.dll,3"
    }
}

function Add-MikesVerb($rootKey, $verbName, $label, $icon, $command) {
    $verbKey = "$rootKey\shell\$verbName"
    $cmdKey = "$verbKey\command"
    New-Item -Path $verbKey -Force | Out-Null
    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -LiteralPath $verbKey -Name "MUIVerb" -Value $label
    Set-ItemProperty -LiteralPath $verbKey -Name "Icon" -Value $icon
    Set-ItemProperty -LiteralPath $cmdKey -Name "(Default)" -Value $command
}

function Remove-ImgGenVerb($rootKey) {
    $verbKey = "$rootKey\shell\ImgGen"
    if (Test-Path -LiteralPath $verbKey) {
        Remove-Item -LiteralPath $verbKey -Recurse -Force
    }
}
