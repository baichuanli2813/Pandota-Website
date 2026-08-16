try {
    $res = Invoke-WebRequest -Uri "https://www.ebay.co.uk/str/geoffscuriosities" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -UseBasicParsing
    $html = $res.Content
    Write-Host "Fetched live store page HTML length:" $html.Length

    if ($html -match '(?i)(\d+%\s*off|coupon|promotion|voucher|save\s+£\d+)') {
        Write-Host "Live eBay Store Promo Detected: " $matches[0]
    } else {
        Write-Host "No active sitewide store coupon promo detected in live store HTML."
    }
} catch {
    Write-Host "Store page fetch error:" $_.Exception.Message
}
