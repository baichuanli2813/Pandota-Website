$text = [System.IO.File]::ReadAllText("inventory.html", [System.Text.Encoding]::UTF8)
$badChar = [char]0x00C2
$cleanText = $text.Replace($badChar.ToString() + "£", "£")
[System.IO.File]::WriteAllText("inventory.html", $cleanText, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Successfully cleaned character encoding in inventory.html!"
