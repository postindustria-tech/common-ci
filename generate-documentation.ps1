
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [string]$GitHubUser = "",
    [string]$GitHubEmail = "",
    [string]$GitHubToken,
    [bool]$SeparateExamples = $False,
    [string]$PullRequestId = ""
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

if ($PullRequestId -ne 0) {

    ./steps/checkout-pr -RepoName $RepoName -PullRequestId $PullRequestId

}

if ($SeparateExamples){
    $ExamplesRepo = "$RepoName-examples"
    
    Write-Output "::group::Clone $ExamplesRepo"
    ./steps/clone-repo.ps1 -RepoName $ExamplesRepo -OrgName $OrgName -DestinationDir $RepoName
    Write-Output "::endgroup::"
    
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }    
}

Write-Output "::group::Clone Tools"
./steps/clone-repo.ps1 -RepoName "tools" -OrgName $OrgName
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Clone Documentation"
if ($RepoName -ne "documentation") {
    ./steps/clone-repo.ps1 -RepoName "documentation" -OrgName $OrgName

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }    
}
Write-Output "::endgroup::"

Write-Output "::group::Generate Documentation"
./steps/generate-documentation.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

exit $LASTEXITCODE
