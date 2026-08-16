$bytes = [System.IO.File]::ReadAllBytes("inventory.html")
$str = [System.Text.Encoding]::ASCII.GetString($bytes)
$pos = $str.IndexOf("inv-card-price")
if ($pos -gt 0) {
    for ($i = $pos; $i -lt ($pos + 35); $i++) {
        Write-Host ("Byte " + $i + " : 0x{0:X2} ('{1}')" -f $bytes[$i], [char]$bytes[$i])
    }
}
