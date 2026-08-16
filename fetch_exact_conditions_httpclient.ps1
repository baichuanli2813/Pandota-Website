Add-Type -AssemblyName System.Net.Http

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
$client.DefaultRequestHeaders.Add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
$client.DefaultRequestHeaders.Add("Accept-Language", "en-GB,en;q=0.9")

$testIds = @("267729753193", "267729862669", "267755974090", "267707331524", "267753890742")

foreach ($id in $testIds) {
    $url = "https://www.ebay.co.uk/itm/$id"
    try {
        $html = $client.GetStringAsync($url).Result
        
        $cond = ""
        if ($html -match '"conditionDisplayName":"([^"]+)"') {
            $cond = $matches[1]
        } elseif ($html -match 'Condition:</span>.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>') {
            $cond = $matches[1].Trim()
        } elseif ($html -match '"itemCondition":"https://schema\.org/([^"]+)"') {
            $cond = $matches[1]
        }
        
        Write-Host "Item $id => Condition: '$cond' (Length: "$html.Length")"
    } catch {
        Write-Host "Item $id Error:" $_.Exception.Message
    }
}
