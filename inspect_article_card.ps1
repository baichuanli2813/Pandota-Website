$htmlCombined = ""
for ($p = 1; $p -le 6; $p++) {
    $path = "ebay_page_$p.html"
    if (Test-Path $path) {
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $htmlCombined += [System.Text.Encoding]::UTF8.GetString($bytes) + "`n`n"
    }
}

$pos = $htmlCombined.IndexOf("data-testid=ig-267745470208")
if ($pos -gt 0) {
    $posEnd = $htmlCombined.IndexOf("</article>", $pos)
    if ($posEnd -gt $pos) {
        $cardHtml = $htmlCombined.Substring($pos, $posEnd - $pos + 10)
        Write-Host "=== ARTICLE CARD HTML ==="
        Write-Host $cardHtml
        Write-Host "========================="
    }
}
