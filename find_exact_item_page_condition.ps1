$h = Get-Content -Path "test_item.html" -Raw

# Search for conditionDisplayName or ux-textspans near Condition
$matches = [regex]::Matches($h, '(?i)"conditionDisplayName":"([^"]+)"')
foreach ($m in $matches) {
    Write-Host "Found conditionDisplayName:" $m.Groups[1].Value
}

$matches2 = [regex]::Matches($h, '(?i)Condition:</span>.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>')
foreach ($m in $matches2) {
    Write-Host "Found Condition textspan:" $m.Groups[1].Value
}

$matches3 = [regex]::Matches($h, '(?i)itemCondition":\s*"([^"]+)"')
foreach ($m in $matches3) {
    Write-Host "Found itemCondition:" $m.Groups[1].Value
}
