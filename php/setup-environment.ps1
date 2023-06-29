param (
    [Parameter(Mandatory=$true)]
    [string]$LanguageVersion
)

if ($env:GITHUB_JOB -eq "PreBuild") {
    Write-Output "Skipping environment setup in PreBuild step"
    exit 0
}

Write-Output "Checking PHP version"
$version = (-split (php --version))[1]
Write-Output "Environment has PHP $version"

if (-not $version.StartsWith($LanguageVersion)) {
    throw "Wrong PHP version in the environment"
}
