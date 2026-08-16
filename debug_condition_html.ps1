$h = Get-Content -Path "test_item.html" -Raw

# Print lines containing "Opened", "Used", "New", "condition"
$lines = $h -split "`n"
foreach ($line in $lines) {
    if ($line -match 'condition' -or $line -match 'Opened' -or $line -match 'Item condition') {
        Write-Host "MATCH LINE:" $line.Substring(0, [Math]::Min(300, $line.Length))
    }
}
