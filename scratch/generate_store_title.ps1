Add-Type -AssemblyName System.Drawing

function Generate-MIF {
    param (
        [string]$text,
        [string]$filename,
        [int]$width,
        [int]$height,
        [int]$fontSize
    )

    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
    
    $g.Clear([System.Drawing.Color]::White)
    
    $font = New-Object System.Drawing.Font("Impact", $fontSize, [System.Drawing.FontStyle]::Regular)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    
    $rect = New-Object System.Drawing.RectangleF(0, 0, $width, $height)
    
    $g.DrawString($text, $font, $brush, $rect, $format)
    
    $depth = $width * $height
    
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("DEPTH = $depth;")
    [void]$sb.AppendLine("WIDTH = 1;")
    [void]$sb.AppendLine("ADDRESS_RADIX = HEX;")
    [void]$sb.AppendLine("DATA_RADIX = BIN;")
    [void]$sb.AppendLine("CONTENT BEGIN")
    
    $addr = 0
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $pixel = $bmp.GetPixel($x, $y)
            if ($pixel.R -lt 128) {
                $hexAddr = $addr.ToString("X")
                [void]$sb.AppendLine("$hexAddr : 1;")
            } else {
                $hexAddr = $addr.ToString("X")
                [void]$sb.AppendLine("$hexAddr : 0;")
            }
            $addr++
        }
    }
    
    [void]$sb.AppendLine("END;")
    
    [System.IO.File]::WriteAllText($filename, $sb.ToString())
    Write-Host "Created $filename successfully!"
    
    $g.Dispose()
    $bmp.Dispose()
    $font.Dispose()
    $brush.Dispose()
    $format.Dispose()
}

Generate-MIF -text "STORE" -filename "c:\Quartus_Projects\shared_project\MIF\store_title.mif" -width 256 -height 64 -fontSize 48
