Add-Type -AssemblyName System.Net.Http

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
$client.DefaultRequestHeaders.Add("Accept-Language", "en-GB,en;q=0.9")

$html = $client.GetStringAsync("https://www.ebay.co.uk/itm/267753890742").Result

# Save to html file for full inspection
[System.IO.File]::WriteAllText("item_267753890742.html", $html, [System.Text.Encoding]::UTF8)

# Find all JSON-LD script blocks
$matches = [regex]::Matches($html, '(?s)<script type="application/ld\+json">(.*?)</script>')
Write-Host "JSON-LD blocks found:" $matches.Count
foreach ($m in $matches) {
    Write-Host "JSON-LD snippet:" $m.Groups[1].Value.Substring(0, [Math]::Min(300, $m.Groups[1].Value.Length))
}

# Find any occurrence of condition in the page
$cMatches = [regex]::Matches($html, '(?i)"[^"]*condition[^"]*"\s*:\s*"([^"]+)"')
foreach ($m in $cMatches) {
    Write-Host "Found condition key/val:" $m.Groups[0].Value
}
