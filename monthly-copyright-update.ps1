
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubUser,
    [Parameter(Mandatory=$true)]
    [string]$GitHubEmail,
    [string]$GitHubToken,
    [bool]$DryRun = $False
)

. ./constants.ps1

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken -GitHubUser $GitHubUser -GitHubEmail $GitHubEmail
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName - $CopyrightUpdateBranch"
./steps/clone-repo.ps1 -RepoName $RepoName -OrgName $OrgName -Branch $CopyrightUpdateBranch
Write-Output "::endgroup::"

Write-Output "::group::Clone Tools"
./steps/clone-repo.ps1 -RepoName "tools" -OrgName $OrgName
Write-Output "::endgroup::"

Write-Output "::group::Options"
$Options = @{
    TargetRepo = $RepoName
}
Write-Output "::endgroup::"

Write-Output "::group::Update Copyright"
./steps/run-repo-script.ps1 -RepoName "tools" -ScriptName "update-copyright.ps1" -Options $Options
Write-Output "::endgroup::"

Write-Output "::group::Has Changed"
./steps/has-changed.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

if ($LASTEXITCODE -eq 0) {
    
    Write-Output "::group::Commit Changes"
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated copyright."
    Write-Output "::endgroup::"

    Write-Output "::group::Push Changes"
    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $CopyrightUpdateBranch -DryRun $DryRun
    Write-Output "::endgroup::"

    Write-Output "::group::PR To Main"
    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated copyright." -GitHubToken $GitHubToken -DryRun $DryRun
    Write-Output "::endgroup::"

}
else {

    Write-Host "No copyright changes, so not creating a pull request."

}

exit 0
