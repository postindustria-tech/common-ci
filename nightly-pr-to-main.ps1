
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

$Success = $True;

foreach ($Options in $(Get-Content $OptionsFile | ConvertFrom-Json)) {

    ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "build-project.ps1" -Options $Options

    if ($LASTEXITCODE -eq 0) {

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-unit-tests.ps1" -Options $Options

    }

    if ($LASTEXITCODE -eq 0) {

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-integration-tests.ps1" -Options $Options

    }

    if ($LASTEXITCODE -eq 0) {

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-performance-tests.ps1" -Options $Options

    }

    $Success = $Success -and $($LASTEXITCODE -eq 0)

}

if ($Success) {

     ./steps/merge-pr.ps1 -RepoName $RepoName -PullRequestId $PullRequestId   

}