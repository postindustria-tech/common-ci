
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    [Parameter(Mandatory=$true)]
    [string]$GitHubOutput,
    [string]$GitHubUser = "",
    [string]$GitHubEmail = "",
    [Parameter(Mandatory=$true)]
    [string]$PullRequestId,
    [Parameter(Mandatory=$true)]
    $Options,
    $RunId = 0,
    [bool]$DryRun = $False
)

. ./constants.ps1

if ($GitHubUser -eq "") {
    $GitHubUser = $DefaultGitUser
}
if ($GitHubEmail -eq "") {
    $GitHubEmail = $DefaultGitEmail
}

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken -GitHubUser $GitHubUser -GitHubEmail $GitHubEmail
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName"
./steps/clone-repo.ps1 -RepoName $RepoName -OrgName $OrgName -Branch $BranchName
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($True -ne $env:CI) {
    # The REST API cannot be used while the workflow is running. So in CI,
    # a GitHub Actions step is used instead.
    # See https://github.com/actions/upload-artifact/issues/53
    Write-Output "::group::Download Performance Artifact"
    ./steps/download-artifact.ps1 -RepoName $RepoName -OrgName $OrgName -RunId $RunId -ArtifactName "performance_results_$PullRequestId" -GitHubToken $GitHubToken
    Write-Output "::endgroup::"
}


Write-Output "::group::Compare Performance Results"
./steps/compare-performance.ps1 -RepoName $RepoName -OrgName $OrgName -RunId $RunId -PullRequestId $PullRequestId -AllOptions $Options -DryRun $DryRun
Write-Output "::endgroup::"

exit $LASTEXITCODE
