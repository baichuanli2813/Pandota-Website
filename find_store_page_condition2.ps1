$bytes = [System.IO.File]::ReadAllBytes("ebay_page_1.html")
$html = [System.Text.Encoding]::UTF8.GetString($bytes)

$pos = $html.IndexOf("267729753193")
if ($pos -gt 0) {
    Write-Host $html.Substring($pos + 1200, 2000)
}
