
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    [Parameter(Mandatory=$true)]
    [string]$GitHubOutput,
    [Parameter(Mandatory=$true)]
    [string]$PullRequestId,
    [Parameter(Mandatory=$true)]
    $Options,
    $RunId = 0
)

. ./constants.ps1

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName"
./steps/clone-repo.ps1 -RepoName $RepoName -Branch $BranchName
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Download Performance Artifact"
./steps/download-artifact.ps1 -RepoName $RepoName -RunId $RunId -ArtifactName "performance_results_$PullRequestId"
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    Write-Output "::group::Compare Performance Results"
    ./steps/compare-performance.ps1 -RepoName $RepoName -RunId $RunId -PullRequestId $PullRequestId -AllOptions $Options
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

exit 0