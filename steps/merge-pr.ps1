param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [Parameter(Mandatory=$true)]
    [int]$PullRequestId,
    [bool]$DryRun = $False
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
    
    $PrTitle = gh pr view $PullRequestId --json number,headRefName,baseRefName,title -t '#{{.number}} {{.headRefName}}->{{.baseRefName}} : {{.title}}'

    Write-Output "Merging PR $PrTitle"
    $Command = {gh api /repos/$OrgName/$RepoName/pulls/$PullRequestId/merge -X PUT -f "commit_title=Merged Pull Request '$PrTitle'"}
    if ($DryRun -eq $False) {
        & $Command
    }
    else {
        Write-Output "Dry run - not executing the following: $Command"
    }
    
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
