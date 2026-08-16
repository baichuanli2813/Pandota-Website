$h = Get-Content -Path "inventory.html" -Raw
$cleanH = $h -replace 'Â£', '£'
[System.IO.File]::WriteAllText("inventory.html", $cleanH, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Cleaned pound symbols in inventory.html!"
