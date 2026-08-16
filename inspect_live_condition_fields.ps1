Add-Type -AssemblyName System.Net.Http

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
$client.DefaultRequestHeaders.Add("Accept-Language", "en-GB,en;q=0.9")

$testIds = @("267729862669", "267755974090", "267753890742", "267729753193")

foreach ($id in $testIds) {
    $url = "https://www.ebay.co.uk/itm/$id"
    try {
        $html = $client.GetStringAsync($url).Result
        
        Write-Host "=== ITEM $id ==="
        
        # 1. Look for schema condition
        if ($html -match '"itemCondition":"https://schema\.org/([^"]+)"') {
            Write-Host "Schema itemCondition:" $matches[1]
        }
        
        # 2. Look for conditionDisplayName
        if ($html -match '"conditionDisplayName":"([^"]+)"') {
            Write-Host "conditionDisplayName:" $matches[1]
        }
        
        # 3. Look for ux-labels-values condition
        $mText = [regex]::Matches($html, '(?i)Item condition:.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>')
        foreach ($m in $mText) {
            Write-Host "Item condition textspan:" $m.Groups[1].Value
        }
        
        # 4. Look for secondary condition label
        $mText2 = [regex]::Matches($html, '(?i)"text":"(Opened[^"]*|New[^"]*|Used[^"]*|Refurbished[^"]*|For parts[^"]*)"')
        foreach ($m in ($mText2 | Select-Object -First 5)) {
            Write-Host "Matched text:" $m.Groups[1].Value
        }
        
        Write-Host "================`n"
    } catch {
        Write-Host "Item $id Error:" $_.Exception.Message
    }
}
