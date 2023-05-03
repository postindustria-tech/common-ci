param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [int]$PullRequestId,
    [string]$VariableName = "PullRequestSha"
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
    Write-Output "Merging in any changes from main"
    git merge origin/main
    
    # Any submodules may not have updated, so do this manually.
    git submodule update --init --recursive

    $Sha = hub pr show $PullRequestId -f "%sH"
    Write-Output "Setting '$VariableName' to '$Sha'"
    Set-Variable -Name $VariableName -Value $Sha -Scope Global

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
