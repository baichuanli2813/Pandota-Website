$url = "https://www.ebay.co.uk/itm/267755974090"
$res = Invoke-WebRequest -Uri $url -Headers @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'} -MaximumRedirection 5
$html = $res.Content

Write-Host "Item HTML Length:" $html.Length

# Search for condition strings on live item page
# On eBay item pages: <div class="ux-labels-values__values-content">...<span class="ux-textspans font-weight-bold">Opened – never used</span>
$matches = [regex]::Matches($html, 'Condition:.*?<span[^>]*class="ux-textspans[^"]*"[^>]*>([^<]+)</span>')
foreach ($m in $matches) {
    Write-Host "Condition Match 1:" $m.Groups[1].Value
}

$matches2 = [regex]::Matches($html, '"conditionDisplayName":"([^"]+)"')
foreach ($m in $matches2) {
    Write-Host "Condition Match 2:" $m.Groups[1].Value
}

$matches3 = [regex]::Matches($html, '"condition":"([^"]+)"')
foreach ($m in $matches3) {
    Write-Host "Condition Match 3:" $m.Groups[1].Value
}
