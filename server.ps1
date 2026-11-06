# Built-in High-Performance HTTP Server for "دليل تخصصي" PWA
param([int]$Port = 5000)
$Prefix = "http://localhost:$Port/"
$RootPath = $PSScriptRoot

if (-not $RootPath) {
    $RootPath = (Get-Location).Path
}

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add($Prefix)

try {
    $Listener.Start()
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " 🎓 خادم تطبيق 'دليل تخصصي' يعمل الآن بنجاح على:" -ForegroundColor Green
    Write-Host "    $Prefix" -ForegroundColor Yellow
    Write-Host " اضغط Ctrl+C لإيقاف الخادم في أي وقت." -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
} catch {
    Write-Host "Error starting listener: $_" -ForegroundColor Red
    exit 1
}

$MimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".webmanifest" = "application/manifest+json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml; charset=utf-8"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
}

while ($Listener.IsListening) {
    try {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        $UrlPath = [System.Uri]::UnescapeDataString($Request.Url.AbsolutePath)
        if ($UrlPath -eq "/" -or [string]::IsNullOrWhiteSpace($UrlPath)) {
            $UrlPath = "/index.html"
        }

        # Normalize relative path
        $FilePath = Join-Path $RootPath ($UrlPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar))

        # Add CORS & Caching headers
        $Response.Headers.Add("Access-Control-Allow-Origin", "*")
        $Response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        if ($Request.HttpMethod -eq "OPTIONS") {
            $Response.StatusCode = 200
            $Response.Close()
            continue
        }

        if (Test-Path $FilePath -PathType Leaf) {
            $Ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
            $ContentType = $MimeTypes[$Ext]
            if (-not $ContentType) { $ContentType = "application/octet-stream" }

            $Response.ContentType = $ContentType
            $Response.StatusCode = 200

            $Bytes = [System.IO.File]::ReadAllBytes($FilePath)
            $Response.ContentLength64 = $Bytes.Length
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        } else {
            $Response.StatusCode = 404
            $ErrBytes = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found: $UrlPath")
            $Response.OutputStream.Write($ErrBytes, 0, $ErrBytes.Length)
        }
        $Response.Close()
    } catch {
        # continue loop
    }
}
