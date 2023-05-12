
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    [int]$RunId = 0
)

. ./constants.ps1

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName"
./steps/clone-repo.ps1 -RepoName $RepoName -Branch $SubModuleUpdateBranch
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Update Submodules"
./steps/update-sub-modules.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Check for Changes"
./steps/has-changed.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

if ($LASTEXITCODE -eq 0) {
    
    Write-Output "::group::Commit Changes"
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated submodules."
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    Write-Output "::group::Push Changes"
    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $SubModuleUpdateBranch
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    Write-Output "::group::Create Pull Request"
    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated submodule."
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
}
else {

    Write-Output "No submodule changes, so not creating a pull request."

    if ($RunId -gt 0) {
        Write-Output "Cancelling Run"
        hub api /repos/51Degrees/$RepoName/actions/runs/$RunId/cancel -X POST
    }
}