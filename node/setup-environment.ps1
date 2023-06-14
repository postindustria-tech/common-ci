param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName

Write-Output "Setuping environment insede $RepoName"

npm install
npm install jest --global

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Pop-Location
