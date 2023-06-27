
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [string]$GitHubUser = "",
    [string]$GitHubEmail = "",
    [string]$GitHubToken,
    [bool]$DryRun = $False,
    [bool]$SeparateExamples= $False
)

./generate-documentation.ps1 `
    -RepoName $RepoName `
    -OrgName $OrgName `
    -GitHubUser $GitHubUser `
    -GitHubEmail $GitHubEmail `
    -GitHubToken $GitHubToken `
    -SeparateExamples $SeparateExamples

if ($SeparateExamples){
    $ExamplesRepo = "$RepoName-examples"
    $ExamplesPath = [IO.Path]::Combine($RepoName, $ExamplesRepo)
    Write-Output "::group::Removing $ExamplesRepo"
    Remove-Item -Path $ExamplesPath -Recurse -Force
    Write-Output "::endgroup::"
    
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }    
}

Write-Output "::group::Has Changed"
./steps/has-changed.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

if ($LASTEXITCODE -eq 0) {
    
    Write-Output "::group::Commit Changes"
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated documentation."
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    Write-Output "::group::Push Changes"
    ./steps/push-changes.ps1 -RepoName $RepoName -Branch gh-pages -DryRun $DryRun
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
}
else {

    Write-Host "No property changes, so not pushing changes."

}

exit 0
