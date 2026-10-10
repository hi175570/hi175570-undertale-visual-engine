param(
    [Parameter(Mandatory = $true)]
    [string] $Path
)

$resolvedPath = [System.IO.Path]::GetFullPath($Path)
$source = [System.IO.File]::ReadAllBytes($resolvedPath)
$output = [System.Collections.Generic.List[byte]]::new($source.Length)
$converted = 0

for ($index = 0; $index -lt $source.Length;) {
    if ($index + 5 -lt $source.Length -and
        $source[$index] -eq 0xED -and
        $source[$index + 1] -ge 0xA0 -and $source[$index + 1] -le 0xAF -and
        $source[$index + 2] -ge 0x80 -and $source[$index + 2] -le 0xBF -and
        $source[$index + 3] -eq 0xED -and
        $source[$index + 4] -ge 0xB0 -and $source[$index + 4] -le 0xBF -and
        $source[$index + 5] -ge 0x80 -and $source[$index + 5] -le 0xBF) {
        $high = 0xD800 + (($source[$index + 1] -band 0x0F) -shl 6) + ($source[$index + 2] -band 0x3F)
        $low = 0xDC00 + (($source[$index + 4] -band 0x0F) -shl 6) + ($source[$index + 5] -band 0x3F)
        $codePoint = 0x10000 + (($high - 0xD800) -shl 10) + ($low - 0xDC00)
        $output.Add([byte](0xF0 -bor ($codePoint -shr 18)))
        $output.Add([byte](0x80 -bor (($codePoint -shr 12) -band 0x3F)))
        $output.Add([byte](0x80 -bor (($codePoint -shr 6) -band 0x3F)))
        $output.Add([byte](0x80 -bor ($codePoint -band 0x3F)))
        $index += 6
        $converted += 1
        continue
    }
    $output.Add($source[$index])
    $index += 1
}

if ($converted -le 0) {
    [pscustomobject]@{ Path = $resolvedPath; Converted = 0; Changed = $false }
    exit 0
}

$backupPath = "$resolvedPath.before-unicode-repair.bak"
[System.IO.File]::Copy($resolvedPath, $backupPath, $true)
$temporaryPath = "$resolvedPath.unicode-repair.tmp"
[System.IO.File]::WriteAllBytes($temporaryPath, $output.ToArray())
$strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
$decoded = $strictUtf8.GetString([System.IO.File]::ReadAllBytes($temporaryPath))
$null = $decoded | ConvertFrom-Json
[System.IO.File]::Move($temporaryPath, $resolvedPath, $true)

[pscustomobject]@{
    Path = $resolvedPath
    Backup = $backupPath
    Converted = $converted
    Changed = $true
}
