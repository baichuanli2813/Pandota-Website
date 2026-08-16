$html = Get-Content -Path "alienware_page.html" -Raw

Write-Host "File Length:" $html.Length

# Search for "Condition:" or itemCondition in alienware_page.html
$matches1 = [regex]::Matches($html, '(?i)Condition:</span>.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>')
foreach ($m in $matches1) {
    Write-Host "Condition textspan match:" $m.Groups[1].Value
}

$matches2 = [regex]::Matches($html, '(?i)"conditionDisplayName"\s*:\s*"([^"]+)"')
foreach ($m in $matches2) {
    Write-Host "conditionDisplayName match:" $m.Groups[1].Value
}

$matches3 = [regex]::Matches($html, '(?i)"itemCondition"\s*:\s*"https://schema\.org/([^"]+)"')
foreach ($m in $matches3) {
    Write-Host "itemCondition schema match:" $m.Groups[1].Value
}

$matches4 = [regex]::Matches($html, '(?i)class="ux-labels-values__values-content"[^>]*>.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>')
foreach ($m in ($matches4 | Select-Object -First 10)) {
    Write-Host "ux-labels-values content match:" $m.Groups[1].Value
}
