
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$GitHubToken
)

. ./constants.ps1

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName - $CopyrightUpdateBranch"
./steps/clone-repo.ps1 -RepoName $RepoName -Branch $CopyrightUpdateBranch
Write-Output "::endgroup::"

Write-Output "::group::Clone Tools"
./steps/clone-repo.ps1 -RepoName "tools"
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
    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $CopyrightUpdateBranch
    Write-Output "::endgroup::"

    Write-Output "::group::PR To Main"
    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated copyright."
    Write-Output "::endgroup::"

}
else {

    Write-Host "No copyright changes, so not creating a pull request."

}

exit 0
