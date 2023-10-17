
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    [string]$GitHubUser = "",
    [string]$GitHubEmail = "",
    [Parameter(Mandatory=$true)]
    [string]$GitHubOutput,
    [Parameter(Mandatory=$true)]
    [string]$VariableName
)

# If the list of pull requests is provided as a CI parameter - output it and exit early.
# An environment variable is used instead of a parameter to avoid arbitrary code injection.
if ($env:PULL_REQUEST_IDS) {
    Write-Output "Pull request ids are: $env:PULL_REQUEST_IDS"
    "pull_request_ids=[$env:PULL_REQUEST_IDS]" | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
    return
}

. ./constants.ps1

if ($GitHubUser -eq "") {
    $GitHubUser = $DefaultGitUser
}
if ($GitHubEmail -eq "") {
    $GitHubEmail = $DefaultGitEmail
}

# This token is used by the gh command.
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

Write-Output "::group::Get Pull Requests"
./steps/get-pull-requests.ps1 -RepoName $RepoName -OrgName $OrgName -VariableName $VariableName -GitHubToken $GitHubToken
Write-Output pull_request_ids="[$([string]::Join(",", $PullRequestIds))]" | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
