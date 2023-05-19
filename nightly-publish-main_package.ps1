
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
    [Hashtable]$Options
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
./steps/clone-repo.ps1 -RepoName $RepoName -OrgName $OrgName
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Install Package From Artifact"
./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "install-package.ps1" -Options $Options
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Output "::group::Publish Packages"
./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "publish-package.ps1" -Options $Options
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Output "::group::Update Tag"
./steps/update-tag.ps1 -RepoName $RepoName -OrgName $OrgName -Tag $Options.Version
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
