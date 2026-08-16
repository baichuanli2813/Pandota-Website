$bytes = [System.IO.File]::ReadAllBytes("inventory.html")

# Find pattern 0xC2 0xC2 0xA3 and replace with 0xC2 0xA3
$newBytes = [System.Collections.Generic.List[byte]]::new()

for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($i -lt ($bytes.Length - 2) -and $bytes[$i] -eq 0xC2 -and $bytes[$i+1] -eq 0xC2 -and $bytes[$i+2] -eq 0xA3) {
        $newBytes.Add([byte]0xC2)
        $newBytes.Add([byte]0xA3)
        $i += 2
    } else {
        $newBytes.Add($bytes[$i])
    }
}

[System.IO.File]::WriteAllBytes("inventory.html", $newBytes.ToArray())
Write-Host "Exact byte pattern 0xC2 0xC2 0xA3 replaced with 0xC2 0xA3 in inventory.html!"
