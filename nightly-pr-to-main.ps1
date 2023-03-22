
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [int32]$PullRequestId
)

. ./constants.ps1

./steps/clone-repo.ps1 -RepoName $RepoName -Branch $BranchName

./steps/checkout-pr.ps1 -RepoName $RepoName -PullRequestId $PullRequestId

./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "fetch-assets.ps1"

./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "build-project.ps1" -Result Result

if ($Result -eq $True) {

    ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-unit-tests.ps1" -Result Result

}

if ($Result -eq $True) {

    ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-integration-tests.ps1" -Result Result

}

if ($Result -eq $True) {

    ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-performance-tests.ps1" -Result Result

}

if ($Result -eq $True) {

    ./steps/approve-pr.ps1 -RepoName $RepoName -PullRequestId $PullRequestId
    
}