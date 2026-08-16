$htmlCombined = ""
for ($p = 1; $p -le 6; $p++) {
    $path = "ebay_page_$p.html"
    if (Test-Path $path) {
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $htmlCombined += [System.Text.Encoding]::UTF8.GetString($bytes) + "`n`n"
    }
}

$pos = $htmlCombined.IndexOf("267755930402")
if ($pos -gt 0) {
    $snippet = $htmlCombined.Substring($pos, [Math]::Min(1500, $htmlCombined.Length - $pos))
    Write-Host "HP OMEN STORE SNIPPET:"
    Write-Host $snippet
}
