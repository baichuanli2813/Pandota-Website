Add-Type -AssemblyName System.Net.Http

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

$url = "https://www.ebay.co.uk/itm/267755930402"
$html = $client.GetStringAsync($url).Result

[System.IO.File]::WriteAllText("hp_omen_page.html", $html, [System.Text.Encoding]::UTF8)

Write-Host "Page Length:" $html.Length

# Search for condition tags in hp_omen_page.html
$matches = [regex]::Matches($html, '(?i)Opened[^\n<"]*')
foreach ($m in $matches) {
    Write-Host "Opened match:" $m.Value
}

$matches2 = [regex]::Matches($html, '(?i)"condition[^"]*"\s*:\s*"([^"]+)"')
foreach ($m in $matches2) {
    Write-Host "Condition JSON match:" $m.Value
}
