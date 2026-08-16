$h = Get-Content -Path "item_267753890742.html" -Raw
Write-Host "File Length:" $h.Length

$matches = [regex]::Matches($h, '(?i)condition[^\n]{0,100}')
Write-Host "Matches count:" $matches.Count
foreach ($m in ($matches | Select-Object -First 15)) {
    Write-Host $m.Value
}
