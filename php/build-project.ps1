param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName
try {
    composer install --no-interaction || $(throw "composer install failed")
} finally {
    Pop-Location
}
