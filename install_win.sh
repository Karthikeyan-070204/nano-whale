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
    $Asset = $Release.assets | Where-Object { $_.name -eq $AssetName -or $_.name -eq "nano-whale.exe" -or $_.name -like "*windows*.exe" } | Select-Object -First 1
}

# If not found in 'latest', check recent releases
if (-not $Asset) {
    $Releases = try {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Headers $Headers
    } catch {
        @()
    }
    foreach ($rel in $Releases) {
        $found = $rel.assets | Where-Object { $_.name -eq $AssetName -or $_.name -eq "nano-whale.exe" -or $_.name -like "*windows*.exe" } | Select-Object -First 1
        if ($found) {
            $Asset = $found
            Write-Host "Found Windows asset in release $($rel.tag_name)."
            break
        }
    }
}

if (-not $Asset) {
    Write-Error "Could not find a release asset for Windows in $Repo.`n`nOnce the release workflow runs to publish the binary in GitHub Releases, this installer will download it."
    exit 1
}

# Determine install location with automatic fallback if .local\bin is locked
$CandidateDirs = @(
    "$env:USERPROFILE\.local\bin",
    "$env:USERPROFILE\.cargo\bin",
    "$env:USERPROFILE\bin"
)

$InstallDir = $null
foreach ($dir in $CandidateDirs) {
    if (-not (Test-Path $dir)) {
        try { New-Item -ItemType Directory -Force -Path $dir | Out-Null } catch { continue }
    }
    # Test if directory is writable and not locked
    $testPath = Join-Path $dir "nw_probe_$([Guid]::NewGuid().ToString('N')).tmp"
    try {
        [System.IO.File]::WriteAllBytes($testPath, @())
        Remove-Item $testPath -Force -ErrorAction SilentlyContinue
        $InstallDir = $dir
        break
    } catch {
        continue
    }
}

if (-not $InstallDir) {
    $InstallDir = "$env:USERPROFILE\.local\bin"
}

$InstallPath = Join-Path $InstallDir $BinName
$TempPath = Join-Path $env:TEMP "$BinName.tmp"

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

# Replace target binary safely, falling back to .cargo\bin if .local\bin target is locked
$installed = $false
try {
    if (Test-Path $InstallPath) {
        Remove-Item -Path $InstallPath -Force -ErrorAction Stop
    }
    Move-Item -Path $TempPath -Destination $InstallPath -Force -ErrorAction Stop
    $installed = $true
} catch {
    # If the specific file is locked in .local\bin (e.g. antivirus quarantine), use .cargo\bin or ~/bin
    $fallbackDirs = @("$env:USERPROFILE\.cargo\bin", "$env:USERPROFILE\bin")
    foreach ($fb in $fallbackDirs) {
        if (-not (Test-Path $fb)) {
            New-Item -ItemType Directory -Force -Path $fb | Out-Null
        }
        $fbPath = Join-Path $fb $BinName
        try {
            if (Test-Path $fbPath) { Remove-Item -Path $fbPath -Force -ErrorAction SilentlyContinue }
            Move-Item -Path $TempPath -Destination $fbPath -Force -ErrorAction Stop
            $InstallDir = $fb
            $InstallPath = $fbPath
            $installed = $true
            break
        } catch {
            continue
        }
    }
}

if (-not $installed) {
    Write-Error "Failed to install $BinName to $InstallDir. Please check folder permissions or antivirus exclusions."
    exit 1
}

Remove-Item -Path $TempPath -Force -ErrorAction SilentlyContinue

Write-Host "Installation complete! $InstallPath has been created."

# Try updating C:\Program Files\nano-whale if it exists and is writable
$ProgramFilesDir = "$env:ProgramFiles\nano-whale"
$ProgramFilesExe = Join-Path $ProgramFilesDir $BinName
$updatedProgramFiles = $false
if (Test-Path $ProgramFilesExe) {
    try {
        Copy-Item -Path $InstallPath -Destination $ProgramFilesExe -Force -ErrorAction Stop
        $updatedProgramFiles = $true
        Write-Host "Also updated existing binary at $ProgramFilesExe to the Rust release." -ForegroundColor Green
    } catch {
        # Not writable without elevated permissions
    }
}

$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notmatch [regex]::Escape($InstallDir)) {
    Write-Host "Adding $InstallDir to your PATH..."
    $NewPath = "$InstallDir;$UserPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Host "PATH updated. Please restart your terminal for it to take full effect."
}

if ((Test-Path $ProgramFilesExe) -and (-not $updatedProgramFiles)) {
    Write-Host ""
    Write-Host "[WARNING] An older nano-whale executable exists at:" -ForegroundColor Yellow
    Write-Host "  $ProgramFilesExe" -ForegroundColor Yellow
    Write-Host "Windows runs this file first because System PATH takes priority over User PATH." -ForegroundColor Yellow
    Write-Host "To make 'nano-whale' run the Rust edition, run in Administrator PowerShell:" -ForegroundColor Cyan
    Write-Host "  Copy-Item `"$InstallPath`" `"$ProgramFilesExe`" -Force" -ForegroundColor Cyan
    Write-Host "Or delete the old one:" -ForegroundColor Cyan
    Write-Host "  Remove-Item -Force `"$ProgramFilesExe`"" -ForegroundColor Cyan
    Write-Host "Or launch the Rust version directly with:" -ForegroundColor Green
    Write-Host "  & `"$InstallPath`"" -ForegroundColor Green
} else {
    Write-Host "Run 'nano-whale' to start."
}
