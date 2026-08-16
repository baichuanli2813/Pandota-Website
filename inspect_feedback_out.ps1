$html = Get-Content "feedback_api_out.html" -Raw -Encoding utf8

# Check for any script tags containing JSON or state data
$scripts = [regex]::Matches($html, '(?s)<script[^>]*>(.*?)</script>')
Write-Host "Total script tags found:" $scripts.Count

foreach ($s in $scripts) {
    $code = $s.Groups[1].Value
    if ($code -match 'feedback|comment|buyer|rating|score') {
        Write-Host "Found script with feedback data! Length:" $code.Length
        if ($code.Length -lt 2000) {
            Write-Host $code
        } else {
            Write-Host $code.Substring(0, 500) "..."
        }
    }
}
