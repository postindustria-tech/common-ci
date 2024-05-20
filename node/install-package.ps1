param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName

Get-ChildItem -Path ../package -Filter *.tgz | ForEach-Object {
    npm install $_ || $(throw "npm install failed")
}

Pop-Location

