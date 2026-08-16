Add-Type -AssemblyName System.Net.Http

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

$url = "https://www.ebay.co.uk/itm/267755930402?itmmeta=01M0520S7SC8XF0EZCQ545RHJY&hash=item3e577f4322:g:2HwAAeSwSKxqfZrP"
$html = $client.GetStringAsync($url).Result

Write-Host "Page Length:" $html.Length

# Search for condition tags in hp_omen_page.html
$matches = [regex]::Matches($html, '(?i)Item condition:.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>')
foreach ($m in $matches) {
    Write-Host "Item Condition Match:" $m.Groups[1].Value
}

$matches2 = [regex]::Matches($html, '(?i)"conditionDisplayName":"([^"]+)"')
foreach ($m in $matches2) {
    Write-Host "conditionDisplayName Match:" $m.Groups[1].Value
}

$matches3 = [regex]::Matches($html, '(?i)"itemCondition":"https://schema\.org/([^"]+)"')
foreach ($m in $matches3) {
    Write-Host "itemCondition Schema Match:" $m.Groups[1].Value
}
