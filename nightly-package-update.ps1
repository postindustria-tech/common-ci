
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

. ./constants.ps1

$BranchName = $SubModuleUpdateBranch

./steps/clone-repo.ps1 -RepoName $RepoName -Branch $BranchName

./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "package-dependency-update.ps1"

./steps/has-changed.ps1 -RepoName $RepoName

if ($LASTEXITCODE -eq 0) {
    
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated packages."

    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $BranchName

    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated packages."
    
}
else {

    Write-Host "No package changes, so not creating a pull request."

}