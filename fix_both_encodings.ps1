$targetFiles = @(
    "index.html",
    "inventory.html",
    "sell.html",
    "privacy.html",
    "script.js",
    "all_82_with_exact_scraped_prices.json",
    "all_store_listings.json"
)

$pound = [string][char]0x00A3
$str1 = "$([char]0x252C)$([char]0x00FA)"
$str2 = "$([char]0x00C2)$([char]0x00A3)"
$str3 = "$([char]0x00C3)$([char]0x201A)$([char]0x00C2)$([char]0x00A3)"
$str4 = [string][char]0xFFFD # Unicode replacement character

foreach ($file in $targetFiles) {
    if (Test-Path $file) {
        $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

        $content = $content.Replace($str1, $pound).Replace($str2, $pound).Replace($str3, $pound).Replace($str4, $pound)
        
        # Clean double pound signs if any created by replacement
        $content = $content.Replace("$pound$pound", $pound)

        [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Cleaned $file bytes and pound signs!"
    }
}
