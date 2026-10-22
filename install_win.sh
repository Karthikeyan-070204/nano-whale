$ErrorActionPreference = "Stop"
$Repo = if ($env:NANO_WHALE_REPO) { $env:NANO_WHALE_REPO } else { "Vriddhachalam/nano-whale" }
$BinName = "nano-whale.exe"
$AssetName = "nano-whale-windows-x86_64.exe"

Write-Host "Fetching latest release for $AssetName from $Repo..."
$Headers = @{ "User-Agent" = "nano-whale-installer" }

# Fetch latest release
$Release = try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers
} catch {
    $null
}

$Asset = $null
if ($Release -and $Release.assets) {
    $Asset = $Release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
}

# If not found in 'latest', check recent releases specifically for the Rust asset
if (-not $Asset) {
    $Releases = try {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Headers $Headers
    } catch {
        @()
    }
    foreach ($rel in $Releases) {
        $found = $rel.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
        if ($found) {
            $Asset = $found
            Write-Host "Found $AssetName in release $($rel.tag_name)."
            break
        }
    }
}

if (-not $Asset) {
    Write-Error "Could not find a release asset for Windows ($AssetName) in $Repo.`n`nThe Rust release workflow has not yet run to publish the binary in GitHub Releases.`nOnce your PR is merged into the 'rust' branch on $Repo (or triggered via GitHub Actions), the release will be published and this installer will download it."
    exit 1
}

$InstallDir = "$env:USERPROFILE\.local\bin"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

$InstallPath = Join-Path $InstallDir $BinName
$TempPath = Join-Path $InstallDir "$BinName.tmp"

# Stop any running instance of nano-whale to release file lock
$running = Get-Process -Name "nano-whale" -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "Stopping running instance of nano-whale to allow update..."
    Stop-Process -Name "nano-whale" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

$DownloadUrl = $Asset.browser_download_url
Write-Host "Downloading $DownloadUrl..."

# Speed up download by disabling slow PowerShell progress bar
$origProgress = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

try {
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -fsSL -L "$DownloadUrl" -o "$TempPath"
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe exited with error code $LASTEXITCODE"
        }
    } else {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempPath -UseBasicParsing
    }
} catch {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempPath -UseBasicParsing
} finally {
    $ProgressPreference = $origProgress
}

# Replace target binary safely
if (Test-Path $InstallPath) {
    try {
        Remove-Item -Path $InstallPath -Force -ErrorAction Stop
    } catch {
        $oldPath = Join-Path $InstallDir "$BinName.old"
        Remove-Item -Path $oldPath -Force -ErrorAction SilentlyContinue
        Move-Item -Path $InstallPath -Destination $oldPath -Force -ErrorAction SilentlyContinue
    }
}

Move-Item -Path $TempPath -Destination $InstallPath -Force
Remove-Item -Path "$InstallPath.old" -Force -ErrorAction SilentlyContinue

Write-Host "Installation complete! $InstallPath has been created."

$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notmatch [regex]::Escape($InstallDir)) {
    Write-Host "Adding $InstallDir to your PATH..."
    $NewPath = "$InstallDir;$UserPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Host "PATH updated. Please restart your terminal for it to take full effect."
}

Write-Host "Run 'nano-whale' to start."
