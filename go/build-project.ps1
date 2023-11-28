param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName
try {
    Write-Output "Building the submodule..."
    $env:MAKEFLAGS = "-j$([Environment]::ProcessorCount)"
    if ($IsMacOs) {
        $env:MACOSX_DEPLOYMENT_TARGET = sw_vers -productVersion
        Write-Output "macOS deployment target is $($env:MACOSX_DEPLOYMENT_TARGET)"
    }
    dd/scripts/prebuild.ps1 || $(throw "prebuild failed")
} finally {
    Pop-Location
}
