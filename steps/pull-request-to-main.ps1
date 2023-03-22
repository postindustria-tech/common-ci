
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    Write-Output "Creating pull request"
    hub pull-request --no-edit --message $Message

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

