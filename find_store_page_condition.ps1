$bytes = [System.IO.File]::ReadAllBytes("ebay_page_1.html")
$html = [System.Text.Encoding]::UTF8.GetString($bytes)

# Print first 5 items snippet in ebay_page_1.html
$matches = [regex]::Matches($html, 'data-testid=ig-(\d+)')

Write-Host "Total items in page 1:" $matches.Count

foreach ($m in ($matches | Select-Object -First 5)) {
    $id = $m.Groups[1].Value
    $pos = $html.IndexOf($id)
    if ($pos -gt 0) {
        $snippet = $html.Substring($pos, [Math]::Min(1500, $html.Length - $pos))
        Write-Host "=== ITEM $id ==="
        Write-Host $snippet
        Write-Host "================`n"
    }
}
