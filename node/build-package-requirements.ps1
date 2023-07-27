param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [array]$Packages
)

Push-Location $RepoName

try
{
    foreach ($package in $Packages) {
        $path = Join-Path . $package
        Push-Location $path
        Write-Output "Building requirements for $package"

        & "$PSScriptRoot/build-extension.ps1" -PackageName $package

        Pop-Location
    }
}
finally
{
    Pop-Location
}

