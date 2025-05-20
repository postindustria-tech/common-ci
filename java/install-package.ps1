param(
    [Parameter(Mandatory)][string]$RepoName,
    [string]$Name
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$packagePath = "$PWD/package"

$mvnLocalRepo = mvn help:evaluate -Dexpression="settings.localRepository" -q -DforceStdout

Write-Host "Entering '$RepoName'"
Push-Location $RepoName
try {
    Write-Host "Copying packages to the local repository"
    Copy-Item -Recurse "$packagePath/51degrees" "$mvnLocalRepo/com/51degrees"

    Write-Host "Local 51d maven repository contents:"
    Get-ChildItem "$mvnLocalRepo/com/51degrees"
} finally {
    Write-Host "Leaving '$RepoName'"
    Pop-Location
}
