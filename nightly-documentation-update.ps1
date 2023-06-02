
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


if ($SeparateExamples){
# TODO : Remove below and replace with $RepoName-"examples"
    $ExamplesRepo = "device-detection-dotnet-examples"
    Write-Output "::group::Clone $ExamplesRepo"
    ./steps/clone-repo.ps1 -RepoName $ExamplesRepo -OrgName $OrgName -DestinationDir $RepoName

    try{
        $ExamplesPath = [IO.Path]::Combine($pwd, $RepoName, $ExamplesRepo)
        Push-Location $RepoName
        Write-Output $pwd
        git submodule add $ExamplesPath
    }
    finally {
        Pop-Location
        Write-Output $pwd
    }
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

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
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
