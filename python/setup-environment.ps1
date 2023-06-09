param (
    [Parameter(Mandatory=$true)]
    [string]$LanguageVersion,
    [string[]]$Dependencies
)

Write-Output "Checking Python version"
$version = (-split (python --version))[1]
Write-Output "Environment has Python $version"

if (-not $version.StartsWith($LanguageVersion)) {
    throw "Wrong Python version in the environment"
}

Write-Output "Installing dependencies"
pip install --upgrade pip
pip install @Dependencies || $(throw "pip install failed")
