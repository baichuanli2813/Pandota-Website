$res = Invoke-WebRequest -Uri "https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -UseBasicParsing
$res.Content | Out-File -FilePath "ebay_feedback_raw.html" -Encoding utf8
Write-Host "Downloaded HTML length: " $res.Content.Length
