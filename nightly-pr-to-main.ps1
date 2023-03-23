
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

# TODO for now we are assuming the file exists. This needs to be defined in docs.
$OptionsFile = [IO.Path]::Combine($pwd, $RepoName, "ci", "options.json")

foreach ($Options in $(Get-Content $OptionsFile | ConvertFrom-Json)) {

    ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "build-project.ps1" -Result Result -Options $Options

    if ($Result -eq $True) {

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-unit-tests.ps1" -Result Result -Options $Options

    }

    if ($Result -eq $True) {

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-integration-tests.ps1" -Result Result -Options $Options

    }

    if ($Result -eq $True) {

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-performance-tests.ps1" -Result Result -Options $Options

    }

}

if ($Result -eq $True) {

    ./steps/approve-pr.ps1 -RepoName $RepoName -PullRequestId $PullRequestId
    
}
