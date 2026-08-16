try {
    $res = Invoke-WebRequest -Uri "https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -UseBasicParsing
    $html = $res.Content
    Write-Host "Feedback page HTML length:" $html.Length

    # Look for feedback comments or JSON data embedded in page
    if ($html -match '(?i)feedback') {
        Write-Host "Found feedback keywords!"
    }
} catch {
    Write-Host "Error fetching feedback page:" $_.Exception.Message
}
