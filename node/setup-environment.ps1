param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName

Write-Output "Setuping environment insіde $RepoName - [START]"

npm install

Write-Output "Setuping environment insіde $RepoName - [END]"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Pop-Location
