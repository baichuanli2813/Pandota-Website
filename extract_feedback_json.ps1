$res = Invoke-WebRequest -Uri "https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -UseBasicParsing
$html = $res.Content

if ($html -match '(?s)window\.__PRELOADED_STATE__\s*=\s*(\{.*?\});') {
    Write-Host "Found PRELOADED_STATE!"
} elseif ($html -match '(?s)feedbackCards|feedbackComments|reviews') {
    Write-Host "Found feedback cards/comments in HTML!"
} else {
    Write-Host "Checking for text comments in HTML..."
}
