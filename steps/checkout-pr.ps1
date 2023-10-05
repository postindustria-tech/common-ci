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

    $PrTitle = gh pr view $PullRequestId --json number,baseRefName,headRefName,title --jq '"#\(.number) \(.headRefName)->\(.baseRefName) : \(.title)"'

    Write-Output "Checking out PR $PrTitle"
    gh pr checkout $PullRequestId
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    Write-Output "Merging in any changes from main"
    git merge origin/main
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    # Any submodules may not have updated, so do this manually.
    git submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    $Sha = gh pr view $PullRequestId --json headRefOid --jq '.headRefOid'
    Write-Output "Setting '$VariableName' to '$Sha'"
    Set-Variable -Name $VariableName -Value $Sha -Scope Global

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
