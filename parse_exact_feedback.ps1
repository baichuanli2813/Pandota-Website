$html = Get-Content "ebay_feedback_raw.html" -Raw -Encoding utf8

# Check for JSON objects or feedback strings
$matches = [regex]::Matches($html, '(?s)"comment"\s*:\s*"(.*?)".*?"buyer"\s*:\s*"(.*?)"')
Write-Host "Regex matches found:" $matches.Count

# Search for any feedback text strings
$comments = [regex]::Matches($html, '"text"\s*:\s*"([^"]{10,200})"')
Write-Host "Text strings matches found:" $comments.Count
for ($i = 0; $i -lt [Math]::Min(10, $comments.Count); $i++) {
    Write-Host "- " $comments[$i].Groups[1].Value
}
