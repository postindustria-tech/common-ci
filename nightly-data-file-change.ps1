
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$DeviceDetectionKey,
    [string]$DeviceDetectionUrl,
    [string]$GitHubToken
)

. ./constants.ps1

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken
Write-Output "::endgroup::"

Write-Output "::group::Clone $Repo Name - $PropertiesUpdateBranch"
./steps/clone-repo.ps1 -RepoName $RepoName -Branch $PropertiesUpdateBranch
Write-Output "::endgroup::"

Write-Output "::group::Clone Tools"
./steps/clone-repo.ps1 -RepoName "tools"
Write-Output "::endgroup::"

Write-Output "::group::Options"
$Options = @{
    DeviceDetectionKey = $DeviceDetectionKey
    DeviceDetectionUrl = $DeviceDetectionUrl
    TargetRepo = $RepoName
}
Write-Output "::endgroup::"

Write-Output "::group::Fetch Assets"
./steps/run-repo-script.ps1 -RepoName "tools" -ScriptName "fetch-assets.ps1" -Options $Options
Write-Output "::endgroup::"

Write-Output "::group::Generate Accessors"
./steps/run-repo-script.ps1 -RepoName "tools" -ScriptName "generate-accessors.ps1" -Options $Options
Write-Output "::endgroup::"

Write-Output "::group::Has Changed"
./steps/has-changed.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

if ($LASTEXITCODE -eq 0) {
    
    Write-Output "::group::Commit Changes"
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated properties."
    Write-Output "::endgroup::"

    Write-Output "::group::Push Changes"
    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $PropertiesUpdateBranch
    Write-Output "::endgroup::"

    Write-Output "::group::PR To Main"
    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated properties."
    Write-Output "::endgroup::"

}
else {

    Write-Host "No property changes, so not creating a pull request."

}

exit 0
