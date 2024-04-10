param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [array]$Packages,
    [array]$NeedExtensions
)

Push-Location $RepoName

try {
    foreach ($package in $Packages) {
        $path = Join-Path . $package
        Push-Location $path

        Write-Output "Installing dependencies for $package - [START]"
        npm install
        Write-Output "Installing dependencies for $package - [END]"


        if($NeedExtensions -Contains $package){
            & "$PSScriptRoot/build-extension.ps1" -PackageName $package
        }

        Pop-Location
    }
    Write-Output "Linting JS files - $RepoName - [START]"
    npm run lint
    Write-Output "Linting JS files - $RepoName - [END]"
} finally {
    Pop-Location
}

