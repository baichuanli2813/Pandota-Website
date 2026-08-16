$html = Get-Content "ebay_feedback_raw.html" -Raw -Encoding utf8

# Print lines containing "feedback" or "buyer" or "seller"
$lines = $html -split "`n"
$relevant = $lines | Where-Object { $_ -match 'positive|feedback|buyer|rating|comment' }

Write-Host "Relevant lines count:" $relevant.Count
for ($i = 0; $i -lt [Math]::Min(15, $relevant.Count); $i++) {
    $line = $relevant[$i].Trim()
    if ($line.Length -gt 150) { $line = $line.Substring(0, 150) + "..." }
    Write-Host "Line $i :" $line
}
