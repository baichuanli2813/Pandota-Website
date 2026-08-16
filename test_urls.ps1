$urls = @(
    'https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367',
    'https://www.ebay.co.uk/usr/geoff_lee367',
    'https://www.ebay.co.uk/str/geoffscuriosities'
)

foreach ($u in $urls) {
    try {
        $r = Invoke-WebRequest -Uri $u -Method Head -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -UseBasicParsing
        Write-Host "$u ==> $($r.StatusCode)"
    } catch {
        Write-Host "$u ==> $($_.Exception.Message)"
    }
}
