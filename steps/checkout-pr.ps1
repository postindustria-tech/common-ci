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

    if ($PullRequestId -eq 0) {

        Write-Output "Not running for a PR"
        exit 0
    
    }

    # For the format argument, see https://hub.github.com/hub-pr.1.html
    $PrTitle = $(hub pr show $PullRequestId -f "%i %H->%B : '%t'")

    Write-Output "Checking out PR $PrTitle"
    hub pr checkout $PullRequestId
    # Any submodules may not have updated, so do this manually.
    git submodule update --init --recursive

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
