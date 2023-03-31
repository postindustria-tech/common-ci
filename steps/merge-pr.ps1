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

    $PrTitle = $(hub pr show 1 -f "%i %H->%B : '%t'")

    Write-Output "Merging PR $PrTitle"
    hub api /repos/51Degrees/$RepoName/pulls/$PullRequestId/merge -X PUT -f "commit_title=Merged Pull Request '$PullRequestId'"

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}