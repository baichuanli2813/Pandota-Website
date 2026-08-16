foreach ($file in @("index.html", "inventory.html")) {
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $newBytes = [System.Collections.Generic.List[byte]]::new()

    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($i -lt ($bytes.Length - 2) -and $bytes[$i] -eq 0xC2 -and $bytes[$i+1] -eq 0xC2 -and $bytes[$i+2] -eq 0xA3) {
            $newBytes.Add([byte]0xC2)
            $newBytes.Add([byte]0xA3)
            $i += 2
        } elseif ($i -lt ($bytes.Length - 1) -and $bytes[$i] -eq 0xC3 -and $bytes[$i+1] -eq 0x82) {
            # 0xC3 0x82 is UTF-8 for Â, drop it if followed by pound
            if ($i -lt ($bytes.Length - 3) -and $bytes[$i+2] -eq 0xC2 -and $bytes[$i+3] -eq 0xA3) {
                # skip Â
                $i += 1
            } else {
                $newBytes.Add($bytes[$i])
            }
        } else {
            $newBytes.Add($bytes[$i])
        }
    }

    [System.IO.File]::WriteAllBytes($file, $newBytes.ToArray())
    Write-Host "Cleaned $file bytes!"
}
