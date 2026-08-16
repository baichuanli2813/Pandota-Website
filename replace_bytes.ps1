$bytes = [System.IO.File]::ReadAllBytes("inventory.html")
$utf8 = [System.Text.Encoding]::UTF8.GetString($bytes)
$clean = $utf8.Replace("Â£", "£")
$cleanBytes = [System.Text.Encoding]::UTF8.GetBytes($clean)
[System.IO.File]::WriteAllBytes("inventory.html", $cleanBytes)
Write-Host "Cleaned Â£ via UTF8 byte replace!"
