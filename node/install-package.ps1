param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName

npm install (Get-ChildItem -Path ../package -Filter *.tgz) || $(throw "npm install failed")

Pop-Location

