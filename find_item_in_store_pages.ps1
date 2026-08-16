$htmlCombined = ""
for ($p = 1; $p -le 6; $p++) {
    $path = "ebay_page_$p.html"
    if (Test-Path $path) {
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $htmlCombined += [System.Text.Encoding]::UTF8.GetString($bytes) + "`n`n"
    }
}

Write-Host "Combined HTML length:" $htmlCombined.Length

# Search for 267745470208 in htmlCombined
$pos = $htmlCombined.IndexOf("267745470208")
if ($pos -gt 0) {
    Write-Host "Found 267745470208 at index $pos"
    $snippet = $htmlCombined.Substring([Math]::Max(0, $pos - 500), 2000)
    Write-Host $snippet
} else {
    Write-Host "267745470208 not found in store pages HTML"
}
