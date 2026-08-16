$h = Get-Content -Path "ebay_raw.html" -Raw
$pos = $h.IndexOf('data-testid=ig-267755974090')
if ($pos -gt 0) {
    Write-Host $h.Substring($pos, 2500)
}
