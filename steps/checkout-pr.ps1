param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [int]$PullRequestId
)

. ./constants.ps1

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $PrTitle = $(hub pr show $PullRequestId -f "%i %H->%B : '%t'")

    Write-Output "Checking out PR $PrTitle"
    hub pr checkout $PullRequestId

    git submodule update --init --recursive

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}