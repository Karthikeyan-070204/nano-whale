$ErrorActionPreference = "Stop"
$Repo = if ($env:NANO_WHALE_REPO) { $env:NANO_WHALE_REPO } else { "Vriddhachalam/nano-whale" }
$BinName = "nano-whale.exe"
$AssetName = "nano-whale-windows-x86_64.exe"

Write-Host "Fetching latest release for $AssetName from $Repo..."
$Headers = @{ "User-Agent" = "nano-whale-installer" }

# Try fetching releases/latest first
$Release = try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers
} catch {
    $null
}

$Asset = $null
if ($Release -and $Release.assets) {
    $Asset = $Release.assets | Where-Object { $_.name -eq $AssetName -or $_.name -like "*windows*.exe" } | Select-Object -First 1
}

# Fallback: search all releases if latest release doesn't have the Rust binary yet
if (-not $Asset) {
    $Releases = try {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Headers $Headers
    } catch {
        @()
    }
    foreach ($rel in $Releases) {
        $found = $rel.assets | Where-Object { $_.name -eq $AssetName -or $_.name -like "*windows*.exe" } | Select-Object -First 1
        if ($found) {
            $Asset = $found
            Write-Host "Found Windows asset in release $($rel.tag_name)."
            break
        }
    }
}

if (-not $Asset) {
    Write-Error "Could not find a release asset for Windows ($AssetName) in $Repo. The Rust release workflow has not yet been run to publish the binary assets on GitHub. Once the PR is merged into the 'rust' branch (or triggered via GitHub Actions), the release will be published and this command will install it."
    exit 1
}

$DownloadUrl = $Asset.browser_download_url
Write-Host "Downloading $DownloadUrl..."

$InstallDir = "$env:USERPROFILE\.local\bin"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

$InstallPath = Join-Path $InstallDir $BinName
Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallPath

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
