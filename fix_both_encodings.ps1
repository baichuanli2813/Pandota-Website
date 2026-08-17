foreach ($file in @("index.html", "inventory.html", "script.js")) {
    if (Test-Path $file) {
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $newBytes = [System.Collections.Generic.List[byte]]::new()

        for ($i = 0; $i -lt $bytes.Length; $i++) {
            if ($i -lt ($bytes.Length - 2) -and $bytes[$i] -eq 0xC2 -and $bytes[$i+1] -eq 0xC2 -and $bytes[$i+2] -eq 0xA3) {
                $newBytes.Add([byte]0xC2)
                $newBytes.Add([byte]0xA3)
                $i += 2
            } elseif ($i -lt ($bytes.Length - 1) -and $bytes[$i] -eq 0xC3 -and $bytes[$i+1] -eq 0x82) {
                if ($i -lt ($bytes.Length - 3) -and $bytes[$i+2] -eq 0xC2 -and $bytes[$i+3] -eq 0xA3) {
                    $i += 1
                } else {
                    $newBytes.Add($bytes[$i])
                }
            } else {
                $newBytes.Add($bytes[$i])
            }
        }

        [System.IO.File]::WriteAllBytes($file, $newBytes.ToArray())

        # Also ensure UTF-8 strings are clean of any CP437 artifacts
        $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
        $str1 = "$([char]0x252C)$([char]0x00FA)"
        $str2 = "$([char]0x00C2)$([char]0x00A3)"
        $str3 = "$([char]0x00C3)$([char]0x201A)$([char]0x00C2)$([char]0x00A3)"
        $content = $content.Replace($str1, "£").Replace($str2, "£").Replace($str3, "£")
        [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)

        Write-Host "Cleaned $file bytes and pound signs!"
    }
}
