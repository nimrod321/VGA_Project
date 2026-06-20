$files = Get-ChildItem -Path MIF -Filter "*.mif" | Where-Object { $_.Name -match "cop|goblin|maryjane|riddler|robber" }
foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $started = $false
    $minX = 32; $maxX = -1; $minY = 32; $maxY = -1
    $totalNonFF = 0
    foreach ($line in $content) {
        if ($line -match "BEGIN") { $started = $true; continue }
        if ($line -match "END") { $started = $false; break }
        if ($started) {
            if ($line -match "^\s*([0-9A-Fa-f]+)\s*:\s*([0-9A-Fa-f]+)") {
                $addr = [Convert]::ToInt32($Matches[1], 16)
                $val = $Matches[2]
                if ($val -ne "FF") {
                    $x = $addr % 32
                    $y = [Math]::Floor($addr / 32)
                    if ($x -lt $minX) { $minX = $x }
                    if ($x -gt $maxX) { $maxX = $x }
                    if ($y -lt $minY) { $minY = $y }
                    if ($y -gt $maxY) { $maxY = $y }
                    $totalNonFF++
                }
            }
        }
    }
    $width = $maxX - $minX + 1
    $height = $maxY - $minY + 1
    Write-Host "$($file.Name): Width=$width, Height=$height (Bounding Box: X=$minX..$maxX, Y=$minY..$maxY, Active Pixels=$totalNonFF)"
}
