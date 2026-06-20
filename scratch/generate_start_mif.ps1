$text = @(
"                                                                ",
"  SSS  TTTTT   A   RRRR  TTTTT                                  ",
" S       T    A A  R   R   T                                    ",
"  SSS    T   AAAAA RRRR    T                                    ",
"     S   T   A   A R R     T                                    ",
"  SSS    T   A   A R  R    T                                    ",
"                                                                ",
"  PPPPP RRRR  EEEEE  SSS   SSS    EEEEE N   N TTTTT EEEEE RRRR  ",
"  P   P R   R E     S     S       E     NN  N   T   E     R   R ",
"  PPPPP RRRR  EEEE   SSS   SSS    EEEE  N N N   T   EEEE  RRRR  ",
"  P     R R   E         S     S   E     N  NN   T   E     R R   ",
"  P     R  R  EEEEE  SSS   SSS    EEEEE N   N   T   EEEEE R  R  ",
"                                                                ",
"            TTTTT  OOO     SSS  TTTTT   A   RRRR  TTTTT         ",
"              T   O   O   S       T    A A  R   R   T           ",
"              T   O   O    SSS    T   AAAAA RRRR    T           ",
"              T   O   O       S   T   A   A R R     T           ",
"              T    OOO     SSS    T   A   A R  R    T           ",
"                                                                "
)

$WIDTH = 256
$HEIGHT = 64
$DEPTH = $WIDTH * $HEIGHT

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("DEPTH = $DEPTH;")
[void]$sb.AppendLine("WIDTH = 8;")
[void]$sb.AppendLine("ADDRESS_RADIX = HEX;")
[void]$sb.AppendLine("DATA_RADIX = HEX;")
[void]$sb.AppendLine("CONTENT BEGIN")

$addr = 0
for ($y = 0; $y -lt $HEIGHT; $y++) {
    $text_y = [math]::Floor($y / 2)
    for ($x = 0; $x -lt $WIDTH; $x++) {
        $text_x = [math]::Floor($x / 4)
        
        if ($text_y -lt $text.Length -and $text_x -lt $text[$text_y].Length) {
            $char = $text[$text_y][$text_x]
            if ($char -ne ' ') {
                $hexAddr = $addr.ToString("X4")
                [void]$sb.AppendLine("$hexAddr : E0;")
            } else {
                $hexAddr = $addr.ToString("X4")
                [void]$sb.AppendLine("$hexAddr : 00;")
            }
        } else {
            $hexAddr = $addr.ToString("X4")
            [void]$sb.AppendLine("$hexAddr : 00;")
        }
        $addr++
    }
}

[void]$sb.AppendLine("END;")

[System.IO.File]::WriteAllText("c:\Quartus_Projects\shared_project\MIF\start_text.mif", $sb.ToString())
Write-Host "Created start_text.mif successfully!"
