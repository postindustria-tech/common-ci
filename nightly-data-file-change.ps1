
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$DeviceDetection,
    [string]$DeviceDetectionUrl
)

. ./constants.ps1

./steps/clone-repo.ps1 -RepoName $RepoName -Branch $PropertiesUpdateBranch

./steps/clone-repo.ps1 -RepoName "tools"

$Options = @{
    DeviceDetection = $DeviceDetection
    DeviceDetectionUrl = $DeviceDetectionUrl
    TargetRepo = $RepoName
}

./steps/run-repo-script.ps1 -RepoName "tools" -ScriptName "fetch-assets.ps1" -Options $Options

./steps/run-repo-script.ps1 -RepoName "tools" -ScriptName "generate-accessors.ps1" -Options $Options

./steps/has-changed.ps1 -RepoName $RepoName

if ($LASTEXITCODE -eq 0) {
    
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated properties."

    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $BranchName

    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated properties."
    
}
else {

    Write-Host "No property changes, so not creating a pull request."

}