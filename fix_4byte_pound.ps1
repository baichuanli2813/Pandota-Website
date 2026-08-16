$bytes = [System.IO.File]::ReadAllBytes("inventory.html")
$newBytes = [System.Collections.Generic.List[byte]]::new()

for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($i -lt ($bytes.Length - 3) -and $bytes[$i] -eq 0xC3 -and $bytes[$i+1] -eq 0x82 -and $bytes[$i+2] -eq 0xC2 -and $bytes[$i+3] -eq 0xA3) {
        $newBytes.Add([byte]0xC2)
        $newBytes.Add([byte]0xA3)
        $i += 3
    } else {
        $newBytes.Add($bytes[$i])
    }
}

[System.IO.File]::WriteAllBytes("inventory.html", $newBytes.ToArray())
Write-Host "Replaced 4-byte 0xC3 0x82 0xC2 0xA3 with clean 2-byte 0xC2 0xA3 (£) in inventory.html!"
