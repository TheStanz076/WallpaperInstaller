# === Initialization and Logging Setup===
$baseFolder = "C:\Program Files (x86)\Wallpapers"
$archiveBase = Join-Path $baseFolder "Archive"
$fallbackFolder = Join-Path $baseFolder "Fallback"
$wallpaperPath = Join-Path $baseFolder "wallpaper.jpg"
$logFile = "$env:LOCALAPPDATA\Wallpapers\Wallpaper.log"
$logFolder = Split-Path $logFile
if (!(Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

if (!(Test-Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Force | Out-Null
}
function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        Add-Content -Path $logFile -Value "[$timestamp] $msg"
    } catch {
        Write-Host "Log write failed: $msg"
    }
}

Write-Log "Script launched with elevated privileges."
Write-Log "Script launched via batch wrapper."
Write-Log "Base folder: $baseFolder"
Write-Log "Archive folder: $archiveBase"
Write-Log "Fallback folder: $fallbackFolder"
Write-Log "Wallpaper path: $wallpaperPath"

# === Config Parsing ===
function Get-ConfigValue($key, $default) {
    $configPath = Join-Path $baseFolder 'config.ini'
    if (Test-Path $configPath) {
        $lines = Get-Content $configPath | Where-Object {
            ($_ -match "^\s*$key\s*=") -and ($_ -notmatch '^\s*#')
        }
        if ($lines.Count -gt 0) {
            $valueLine = $lines[0]
            $parts = $valueLine -split '=', 2
            if ($parts.Count -eq 2) {
                $value = $parts[1].Trim()
                return $value
            }
        }
    }
    return $default
}

#=== Config Values and Defaults ===
Write-Log "=== Raw config.ini contents ==="
Get-Content (Join-Path $baseFolder 'config.ini') | ForEach-Object { Write-Log $_ }

$imageQuality = Get-ConfigValue 'ImageQuality' '4K'
$region = Get-ConfigValue 'RegionCode' 'en-US'
$scheduleFlag = Get-ConfigValue 'ScheduleTask' '0'
$rawArchiveSize = Get-ConfigValue 'MaxArchiveSizeMB' '500'
Write-Log "Final ImageQuality value: $imageQuality"
Write-Log "Scheduled task creation skipped per config."
Write-Log "Fetching Bing image metadata..."

#=== Debug: Log parsed config values
Write-Log "Parsed ImageQuality: $imageQuality"
Write-Log "Parsed RegionCode: $region"
Write-Log "Parsed MaxArchiveSizeMB: $rawArchiveSize"

# === Bing Image Retrieval ===
$bingURL = "https://www.bing.com/HPImageArchive.aspx?format=js`&idx=$i`&n=1`&mkt=$region"
$response = Invoke-RestMethod -Uri $bingURL -ErrorAction Stop
$baseImageURL = "https://www.bing.com" + $response.images[0].url

if ($imageQuality -eq 'HD') {
    $imgURL = $baseImageURL
} else {
    $imgURL = $baseImageURL -replace "_\d+x\d+\.jpg", "_UHD.jpg"
}
Write-Log "Attempting to download $imageQuality image: $imgURL"

try {
    $headResponse = Invoke-WebRequest -Uri $imgURL -Method Head -ErrorAction SilentlyContinue
    Write-Log "Image URL status: $($headResponse.StatusCode) $($headResponse.StatusDescription)"
    Invoke-WebRequest -Uri $imgURL -OutFile $wallpaperPath -ErrorAction Stop
    $size = (Get-Item $wallpaperPath).Length
    Write-Log "Downloaded image size: $([math]::Round($size/1KB,2)) KB"
} catch {
    Write-Log "Image download failed: $($_.Exception.Message)"
    if ($imageQuality -eq '4K') {
        Write-Log "Falling back to HD image."
        try {
            Invoke-WebRequest -Uri $baseImageURL -OutFile $wallpaperPath -ErrorAction Stop
            $size = (Get-Item $wallpaperPath).Length
            Write-Log "Downloaded HD fallback image size: $([math]::Round($size/1KB,2)) KB"
        } catch {
            Write-Log "HD image also failed: $($_.Exception.Message)"
            $wallpaperPath = $null
        }
    }
}
# === Wallpaper Setting ===
function Set-Wallpaper($path) {
    Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    [Wallpaper]::SystemParametersInfo(20, 0, $path, 3) | Out-Null
    Write-Log "Setting wallpaper: $path"
}

if ($wallpaperPath -and (Test-Path $wallpaperPath)) {
    Set-Wallpaper $wallpaperPath

    # === Archive Logic ===
    $year = (Get-Date).Year
    $month = (Get-Date).ToString("MM-MMMM")
    $archiveFolder = Join-Path $archiveBase "$year\$month"
    if (!(Test-Path $archiveFolder)) {
        Write-Log "Creating archive folder: $archiveFolder"
        New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
    }

    # === First Run: Download Last 8 Bing Wallpapers ===
    $existingImages = Get-ChildItem -Path $archiveFolder -File -ErrorAction SilentlyContinue
    if ($existingImages.Count -eq 0) {
        Write-Log "First run detected — downloading last 8 Bing wallpapers..."
        for ($i = 0; $i -lt 8; $i++) {
            $bingURL = 'https://www.bing.com/HPImageArchive.aspx?format=js' + "&idx=$i&n=1&mkt=$region"
            Write-Log "Fetching archive image metadata from: $bingURL"
            try {
                $response = Invoke-RestMethod -Uri $bingURL -ErrorAction Stop
                $baseImageURL = "https://www.bing.com" + $response.images[0].url
                $imgDate = $response.images[0].startdate
                $imgName = "bing_$imgDate.jpg"
                $imgPath = Join-Path $archiveFolder $imgName

                if (!(Test-Path $imgPath)) {
                    $imgURL = if ($imageQuality -eq 'HD') {
                        $baseImageURL
                    } else {
                        $baseImageURL -replace "_\d+x\d+\.jpg", "_UHD.jpg"
                    }

                    Write-Log "Downloading archive image [$i]: $imgURL"
                    Invoke-WebRequest -Uri $imgURL -OutFile $imgPath -ErrorAction Stop
                    Write-Log "Saved: $imgName"
                } else {
                    Write-Log "Image already exists: $imgName — skipping."
                }
            } catch {
                Write-Log "Failed to download image [$i]: $($_.Exception.Message)"
            }
        }
    }

    $timestamp = Get-Date -Format "yyyyMMdd"
    $archivedImage = "$archiveFolder\bing_$timestamp.jpg"
    Write-Log "Archiving image to: $archivedImage"
    Copy-Item $wallpaperPath -Destination $archivedImage

    # === Archive Purge Logic ===
    $files = Get-ChildItem -Path $archiveBase -Recurse -File
    $archiveSize = ($files | Measure-Object -Property Length -Sum).Sum
    Write-Log "Current archive size: $([math]::Round($archiveSize/1MB,2)) MB"

    if ($rawArchiveSize -notmatch '^\d+$') {
        Write-Log "Warning: MaxArchiveSizeMB value '$rawArchiveSize' is not numeric. Using default 500 MB."
        $maxMB = 500
    } else {
        $maxMB = [int]$rawArchiveSize
    }

    if ($archiveSize -gt ($maxMB * 1MB)) {
        Write-Log "Archive exceeds $maxMB MB. Purging oldest files..."
        $sorted = $files | Sort-Object LastWriteTime
        $purgedSize = 0
        foreach ($file in $sorted) {
            Remove-Item $file.FullName -Force
            $purgedSize += $file.Length
            Write-Log "Purged: $($file.FullName)"
            if (($archiveSize - $purgedSize) -le ($maxMB * 1MB)) {
                break
            }
        }
        Write-Log "Purge complete. Freed $([math]::Round($purgedSize/1MB,2)) MB."
    } else {
        Write-Log "Archive size within limit. No purge needed."
    }

    # === Toast Notification ===
    try {
        $message = "Bing wallpaper updated successfully!"
        Start-Process -FilePath "msg.exe" -ArgumentList "$env:USERNAME", "$message" -WindowStyle Hidden
        Write-Log "Toast notification sent: $message"
    } catch {
        Write-Log "Toast notification failed: $($_.Exception.Message)"
    }

} else {
    Write-Log "Wallpaper image not found. Attempting fallback..."
    if (Test-Path $fallbackFolder) {
        $images = Get-ChildItem -Path $fallbackFolder -File | Where-Object {
            $_.Extension -match '\.jpe?g$|\.png$'
        }
        if ($images.Count -gt 0) {
            $randomImage = Get-Random -InputObject $images
            Write-Log "Selected fallback image: $($randomImage.Name)"
            Set-Wallpaper $randomImage.FullName
        } else {
            Write-Log "No images found in fallback folder."
        }
    } else {
        Write-Log "Fallback folder not found: $fallbackFolder"
    }
}

Write-Log "Script completed."
Write-Host "`nLast 5 log entries:"
Get-Content $logFile | Select-Object -Last 5 | ForEach-Object { Write-Host $_ }
Write-Host "`nScript completed. You can close this window when ready."