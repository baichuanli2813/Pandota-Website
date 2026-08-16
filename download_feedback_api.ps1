$urls = @(
    'https://www.ebay.co.uk/fbc/findFeedback?username=geoff_lee367&filter=FEEDBACK_AS_SELLER',
    'https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367?filter=feedback_page:RECEIVED_AS_SELLER',
    'https://www.ebay.co.uk/usr/geoff_lee367'
)

foreach ($url in $urls) {
    try {
        $res = Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -UseBasicParsing
        Write-Host "URL: $url ==> Length: $($res.Content.Length)"
        if ($res.Content -match '(?i)feedback') {
            $res.Content | Out-File -FilePath "feedback_api_out.html" -Encoding utf8
            Write-Host "Saved response to feedback_api_out.html"
            break
        }
    } catch {
        Write-Host "Error for $url : $($_.Exception.Message)"
    }
}
