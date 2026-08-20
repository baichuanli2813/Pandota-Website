# ==============================================================================
# Pandota Ltd - Instant Local Preview Web Server (Native PowerShell / Zero Install)
# ==============================================================================

$port = 8080
$root = $PSScriptRoot
if (-not $root) { $root = $pwd.Path }

$url = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

try {
    $listener.Start()
} catch {
    $port = 8081
    $url = "http://localhost:$port/"
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($url)
    $listener.Start()
}

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "   PANDOTA WEBSITE - LOCAL PREVIEW SERVER            " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Server running at: $url" -ForegroundColor Yellow
Write-Host " Opening your browser automatically..." -ForegroundColor Gray
Write-Host " (Press Ctrl + C in this window to stop the server)" -ForegroundColor DarkGray
Write-Host "=====================================================" -ForegroundColor Cyan

# Open default web browser
Start-Process $url

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".webp" = "image/webp"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".xml"  = "application/xml; charset=utf-8"
    ".txt"  = "text/plain; charset=utf-8"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $rawPath = $request.Url.LocalPath.TrimStart('/')
        if (-not $rawPath -or $rawPath -eq "") {
            $rawPath = "index.html"
        }

        $filePath = Join-Path $root $rawPath

        # Support clean directory & extensionless URLs (/inventory -> inventory/index.html or inventory.html)
        if (-not (Test-Path $filePath -PathType Leaf)) {
            if (Test-Path (Join-Path $filePath "index.html") -PathType Leaf) {
                $filePath = Join-Path $filePath "index.html"
            } elseif (Test-Path "$filePath.html" -PathType Leaf) {
                $filePath = "$filePath.html"
            }
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
            $response.ContentType = $mime

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.StatusCode = 200
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 Not Found</h1><p>File not found: $rawPath</p>")
            $response.ContentLength64 = $errBytes.Length
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }

        $response.Close()
    } catch {
        # Handle client disconnects or aborts cleanly
    }
}
