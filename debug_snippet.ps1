$h = Get-Content -Path "ebay_raw.html" -Raw
$pos = $h.IndexOf("267755974090")
if ($pos -gt 0) {
    $start = [Math]::Max(0, $pos - 100)
    $len = [Math]::Min(1500, $h.Length - $start)
    Write-Host $h.Substring($start, $len)
}
