
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

. ./constants.ps1

$BranchName = $SubModuleUpdateBranch

./steps/clone-repo.ps1 -RepoName $RepoName -Branch $BranchName

./steps/update-sub-modules.ps1 -RepoName $RepoName

./steps/has-changed.ps1 -RepoName $RepoName

if ($LASTEXITCODE -eq 0) {
    
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated submodules."

    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $BranchName

    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated submodule."

}
else {

    Write-Host "No submodule changes, so not creating a pull request."
    
}