
# Define log file
$logFile = "$baseFolder\bing_wallpaper.log"


# Function to write to log and keep only last 30 days
function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $message"
    Add-Content -Path $logFile -Value $entry

    # Try to get Bing image
    try {
        Write-Log "Fetching Bing image metadata..."
        $bingURL = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
        $response = Invoke-RestMethod -Uri $bingURL -ErrorAction Stop
        $baseImageURL = "https://www.bing.com" + $response.images[0].url
            $quality = Get-ConfigValue 'ImageQuality' '4K'
            if ($quality -eq 'HD') {
                $imgURL = $baseImageURL
                Write-Log "Attempting to download HD image: $imgURL"
            } else {
                $imgURL = $baseImageURL -replace "_\d+x\d+\.jpg", "_UHD.jpg"
                Write-Log "Attempting to download 4K UHD image: $imgURL"
            }
            $downloaded = $false
            try {
                Invoke-WebRequest -Uri $imgURL -OutFile $wallpaperPath -ErrorAction Stop
                $downloaded = $true
                Write-Log "Successfully downloaded image ($quality)."
            } catch {
                if ($quality -eq '4K') {
                    Write-Log "4K UHD image not available, falling back to HD."
                    Invoke-WebRequest -Uri $baseImageURL -OutFile $wallpaperPath -ErrorAction Stop
                } else {
                    Write-Log "HD image not available."
                }
            }
            Set-Wallpaper $wallpaperPath

        function Get-ConfigValue($key, $default) {
            $configPath = Join-Path $baseFolder 'config.ini'
            if (Test-Path $configPath) {
                $lines = Get-Content $configPath | Where-Object { $_ -match "^$key=" }
                if ($lines) {
                    $value = $lines[0] -replace ".*=", ''
                    return $value
                }
            }
            return $default
        }

        # Purge archive if over size limit
        function Purge-ArchiveIfNeeded {
            $maxMB = [int](Get-ConfigValue 'MaxArchiveSizeMB' 500)
            $maxBytes = $maxMB * 1MB
            $archiveSize = (Get-ChildItem -Path $archiveBase -Recurse -File | Measure-Object -Property Length -Sum).Sum
            if ($archiveSize -gt $maxBytes) {
                Write-Log "Archive size $([math]::Round($archiveSize/1MB,2)) MB exceeds limit of $maxMB MB. Purging oldest images..."
                $files = Get-ChildItem -Path $archiveBase -Recurse -File | Sort-Object LastWriteTime
                $size = $archiveSize
                foreach ($file in $files) {
                    if ($size -le $maxBytes) { break }
                    Remove-Item $file.FullName -Force
                    $size -= $file.Length
                    Write-Log "Deleted $($file.FullName) to reduce archive size."
                }
            }
        }

        $year = (Get-Date).Year
        $month = (Get-Date).ToString("MM-MMMM")
        $archiveFolder = Join-Path $archiveBase "$year\$month"
        if (!(Test-Path $archiveFolder)) {
            Write-Log "Creating archive folder: $archiveFolder"
            New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
        }
        $timestamp = Get-Date -Format "yyyyMMdd"
        $archivedImage = "$archiveFolder\bing_$timestamp.jpg"
        Write-Log "Archiving image to: $archivedImage"
        Copy-Item $wallpaperPath -Destination $archivedImage
    }
    catch {
        Write-Log "Error occurred: $($_.Exception.Message)"
        Write-Log "Attempting to use fallback image..."

        $images = Get-ChildItem -Path $fallbackFolder -Include *.jpg, *.png -File
        if ($images.Count -gt 0) {
            $randomImage = Get-Random -InputObject $images
            Write-Log "Selected fallback image: $($randomImage.Name)"
            Set-Wallpaper $randomImage.FullName
        } else {
            Write-Log "No images found in fallback folder."
        }

        Read-Host "Press Enter to close this window"
    }

    # Function to set wallpaper
    function Set-Wallpaper($imagePath) {
        Write-Log "Setting wallpaper: $imagePath"

            # Purge archive if needed
            Purge-ArchiveIfNeeded
        Add-Type @"
        using System.Runtime.InteropServices;
        public class Wallpaper {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        }
    "@
        [Wallpaper]::SystemParametersInfo(20, 0, $imagePath, 3)
    }
        }

        Read-Host "Press Enter to close this window"
    }
        $downloaded = $true
        Write-Log "Successfully downloaded 4K UHD image."
    } catch {
        Write-Log "4K UHD image not available, falling back to HD."
        Invoke-WebRequest -Uri $baseImageURL -OutFile $wallpaperPath -ErrorAction Stop
    }
    Set-Wallpaper $wallpaperPath

    # Archive the image
    $year = (Get-Date).Year
    $month = (Get-Date).ToString("MM-MMMM")
    $archiveFolder = Join-Path $archiveBase "$year\$month"
    if (!(Test-Path $archiveFolder)) {
        Write-Log "Creating archive folder: $archiveFolder"
        New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd"
    $archivedImage = "$archiveFolder\bing_$timestamp.jpg"
    Write-Log "Archiving image to: $archivedImage"
    Copy-Item $wallpaperPath -Destination $archivedImage
}
catch {
    Write-Log "Error occurred: $($_.Exception.Message)"
    Write-Log "Attempting to use fallback image..."

    $images = Get-ChildItem -Path $fallbackFolder -Include *.jpg, *.png -File
    if ($images.Count -gt 0) {
        $randomImage = Get-Random -InputObject $images
    Write-Log "Selected fallback image: $($randomImage.Name)"
        Set-Wallpaper $randomImage.FullName
    } else {
    Write-Log "No images found in fallback folder."
    }

    Read-Host "Press Enter to close this window"
}

Write-Log "Script completed."
