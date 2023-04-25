
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

# Path for the locally installed packages from which they will be uploaded to artifacts
$PackagePath = "$RepoPath/package/"

$LocalRepoPath = [IO.Path]::Combine($home, ".m2", "repository", "com", "51degrees")

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    New-Item -path $LocalRepoPath -ItemType Directory -Force 
    # Copy files over from target to package-files folder
    $RepoPackages = Get-ChildItem -Path $PackagePath
    Copy-Item -Path $RepoPackages -Destination "$LocalRepoPath"


}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
