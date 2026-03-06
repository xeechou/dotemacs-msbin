<#
.SYNOPSIS
    Installs Emacs external dependencies (Git, LLVM, MiKTeX) under a common root.
.DESCRIPTION
    Downloads and silently installs Git for Windows, LLVM/Clang, and MiKTeX
    to $InstallRoot. Already-installed tools are skipped automatically.
    Admin privileges are only required when something actually needs installing.
.EXAMPLE
    .\install-deps.ps1
    .\install-deps.ps1 -InstallRoot "D:\Softwares"
#>
param(
    [string]$InstallRoot = "C:\Softwares"
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

$script:StagingReady = $false

function Assert-ReadyToInstall {
    if ($script:StagingReady) { return }

    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "Installation requires Administrator privileges. Please re-run as Admin."
    }

    $script:StagingDir = Join-Path $env:TEMP "emacs-deps"
    New-Item -ItemType Directory -Force -Path $InstallRoot   | Out-Null
    New-Item -ItemType Directory -Force -Path $script:StagingDir | Out-Null
    $script:StagingReady = $true
}

function Get-GitHubLatestRelease {
    param([string]$Repo)
    $uri = "https://api.github.com/repos/$Repo/releases/latest"
    Invoke-RestMethod -Uri $uri -Headers @{ "User-Agent" = "emacs-deps-installer" }
}

function Add-ToSystemPath {
    param([string]$Dir)
    $current = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($current -split ";" | Where-Object { $_ -eq $Dir }) {
        Write-Host "  $Dir is already on the system PATH."
        return
    }
    [Environment]::SetEnvironmentVariable("Path", "$current;$Dir", "Machine")
    $env:Path = "$env:Path;$Dir"
    Write-Host "  Added $Dir to system PATH."
}

function Test-Installation {
    param(
        [string]$Name,
        [string[]]$Binaries
    )
    $allOk = $true
    foreach ($bin in $Binaries) {
        if (Test-Path $bin) {
            Write-Host "  [PASS] $bin" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $bin not found" -ForegroundColor Red
            $allOk = $false
        }
    }
    if (-not $allOk) {
        Write-Warning "[$Name] Some expected binaries are missing -- installation may have failed."
    }
    return $allOk
}

# ---------------------------------------------------------------------------
# Git for Windows  (InnoSetup installer)
# ---------------------------------------------------------------------------

function Install-Git {
    $targetDir = Join-Path $InstallRoot "Git"

    if (Test-Path (Join-Path $targetDir "cmd\git.exe")) {
        Write-Host "[Git] Already installed at $targetDir -- skipping."
        $script:gitOk = $true
        return
    }

    Assert-ReadyToInstall
    Write-Host "[Git] Resolving latest release..."
    $release = Get-GitHubLatestRelease "git-for-windows/git"
    $asset   = $release.assets |
               Where-Object { $_.name -match "^Git-[\d.]+-64-bit\.exe$" } |
               Select-Object -First 1

    if (-not $asset) { throw "Could not find a 64-bit Git installer in the latest release." }

    $installer = Join-Path $script:StagingDir $asset.name
    Write-Host "[Git] Downloading $($asset.name) ..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer -UseBasicParsing

    Write-Host "[Git] Installing to $targetDir ..."
    $args = @(
        "/VERYSILENT"
        "/NORESTART"
        "/NOICONS"
        "/DIR=`"$targetDir`""
    )
    Start-Process -FilePath $installer -ArgumentList $args -Wait

    Add-ToSystemPath (Join-Path $targetDir "cmd")

    Write-Host "[Git] Verifying installation..."
    $script:gitOk = Test-Installation "Git" @(
        (Join-Path $targetDir "cmd\git.exe"),
        (Join-Path $targetDir "mingw64\bin\git.exe"),
        (Join-Path $targetDir "usr\bin\bash.exe")
    )
    Write-Host "[Git] Done.`n"
}

# ---------------------------------------------------------------------------
# LLVM / Clang  (NSIS installer)
# ---------------------------------------------------------------------------

function Install-LLVM {
    $targetDir = Join-Path $InstallRoot "LLVM"

    if (Test-Path (Join-Path $targetDir "bin\clang.exe")) {
        Write-Host "[LLVM] Already installed at $targetDir -- skipping."
        $script:llvmOk = $true
        return
    }

    Assert-ReadyToInstall
    Write-Host "[LLVM] Resolving latest release..."
    $release = Get-GitHubLatestRelease "llvm/llvm-project"
    $asset   = $release.assets |
               Where-Object { $_.name -match "^LLVM-[\d.]+-win64\.exe$" } |
               Select-Object -First 1

    if (-not $asset) { throw "Could not find a win64 LLVM installer in the latest release." }

    $installer = Join-Path $script:StagingDir $asset.name
    Write-Host "[LLVM] Downloading $($asset.name) ..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer -UseBasicParsing

    # NSIS: /D= must be the very last argument and must NOT be quoted
    Write-Host "[LLVM] Installing to $targetDir ..."
    Start-Process -FilePath $installer -ArgumentList "/S /D=$targetDir" -Wait

    Add-ToSystemPath (Join-Path $targetDir "bin")

    Write-Host "[LLVM] Verifying installation..."
    $script:llvmOk = Test-Installation "LLVM" @(
        (Join-Path $targetDir "bin\clang.exe"),
        (Join-Path $targetDir "bin\clang++.exe"),
        (Join-Path $targetDir "bin\clangd.exe"),
        (Join-Path $targetDir "bin\lld.exe")
    )
    Write-Host "[LLVM] Done.`n"
}

# ---------------------------------------------------------------------------
# MiKTeX  (miktexsetup standalone CLI)
# ---------------------------------------------------------------------------

$MiKTeXSetupUrl = "https://miktex.org/download/ctan/systems/win32/miktex/setup/windows-x64/miktexsetup-5.5.0+1763023-x64.zip"

function Install-MiKTeX {
    $targetDir = Join-Path $InstallRoot "MiKTeX"

    if (Test-Path (Join-Path $targetDir "miktex\bin\x64\pdflatex.exe")) {
        Write-Host "[MiKTeX] Already installed at $targetDir -- skipping."
        $script:miktexOk = $true
        return
    }

    Assert-ReadyToInstall
    $setupZip = Join-Path $script:StagingDir "miktexsetup.zip"
    $setupDir = Join-Path $script:StagingDir "miktexsetup"
    $repoDir  = Join-Path $script:StagingDir "miktex-repo"

    Write-Host "[MiKTeX] Downloading setup utility..."
    Invoke-WebRequest -Uri $MiKTeXSetupUrl -OutFile $setupZip -UseBasicParsing
    Expand-Archive -Path $setupZip -DestinationPath $setupDir -Force

    $setupExe = (Get-ChildItem -Path $setupDir -Filter "miktexsetup*.exe" -Recurse |
                 Select-Object -First 1).FullName

    if (-not $setupExe) { throw "Could not locate miktexsetup executable after extraction." }

    Write-Host "[MiKTeX] Downloading packages (basic set) -- this may take a while..."
    Start-Process -FilePath $setupExe -ArgumentList `
        "--verbose",
        "--local-package-repository=`"$repoDir`"",
        "--package-set=basic",
        "download" -Wait

    Write-Host "[MiKTeX] Installing to $targetDir ..."
    Start-Process -FilePath $setupExe -ArgumentList `
        "--verbose",
        "--local-package-repository=`"$repoDir`"",
        "--package-set=basic",
        "--shared=yes",
        "--modify-path=yes",
        "--common-install=`"$targetDir`"",
        "install" -Wait

    Write-Host "[MiKTeX] Verifying installation..."
    $script:miktexOk = Test-Installation "MiKTeX" @(
        (Join-Path $targetDir "miktex\bin\x64\pdflatex.exe"),
        (Join-Path $targetDir "miktex\bin\x64\xelatex.exe"),
        (Join-Path $targetDir "miktex\bin\x64\bibtex.exe"),
        (Join-Path $targetDir "miktex\bin\x64\miktex-console.exe")
    )
    Write-Host "[MiKTeX] Done.`n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Host "============================================"
Write-Host "  Emacs Dependencies Installer"
Write-Host "  Install root: $InstallRoot"
Write-Host "============================================`n"

$script:gitOk    = $false
$script:llvmOk   = $false
$script:miktexOk = $false

try {
    Install-Git
} catch {
    Write-Warning "Git installation failed: $_"
}

try {
    Install-LLVM
} catch {
    Write-Warning "LLVM installation failed: $_"
}

try {
    Install-MiKTeX
} catch {
    Write-Warning "MiKTeX installation failed: $_"
}

if ($script:StagingReady) {
    Write-Host "Cleaning up staging directory..."
    Remove-Item -Recurse -Force $script:StagingDir -ErrorAction SilentlyContinue
}

Write-Host "`n============================================"
Write-Host "  Verification Summary"
Write-Host "============================================"

$results = @(
    @{ Name = "Git";    Ok = $script:gitOk;    Path = Join-Path $InstallRoot "Git" },
    @{ Name = "LLVM";   Ok = $script:llvmOk;   Path = Join-Path $InstallRoot "LLVM" },
    @{ Name = "MiKTeX"; Ok = $script:miktexOk; Path = Join-Path $InstallRoot "MiKTeX" }
)

foreach ($r in $results) {
    $status = if ($r.Ok) { "OK" } else { "FAILED" }
    $color  = if ($r.Ok) { "Green" } else { "Red" }
    Write-Host ("  {0,-8} {1,-8} {2}" -f $r.Name, "[$status]", $r.Path) -ForegroundColor $color
}

$failures = $results | Where-Object { -not $_.Ok }
if ($failures) {
    Write-Host "`nSome installations failed. Check the output above for details." -ForegroundColor Red
} else {
    Write-Host "`nAll installations verified successfully." -ForegroundColor Green
}
