$html = Get-Content -Path "ebay_raw.html" -Raw
Write-Host "Total length of html:" $html.Length

# Search for any URL in html containing ebay
$urls = [regex]::Matches($html, 'https://[^\s"<>'']+') | ForEach-Object { $_.Value } | Select-Object -Unique

Write-Host "Found total unique URLs:" $urls.Count

$itmUrls = $urls | Where-Object { $_ -like "*itm*" -or $_ -like "*str*" }
Write-Host "Found item/store URLs:" $itmUrls.Count

$itmUrls | Select-Object -First 20
