param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [Parameter(Mandatory=$true)]
    [string]$Tag,
    [bool]$DryRun = $False
)
$RepoPath = [IO.Path]::Combine($pwd, $RepoName)


Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Tagging with '$Tag'"
    git tag $Tag

    Write-Output "Pushing tag"
    $Command = "git push origin $Tag"
    if ($DryRun -eq $False) {
        Invoke-Expression $Command
    }
    else {
        Write-Output "Dry run - not executing the following: $Command"
    }

    # When creating the release, auto-generate the release notes from the
    # PRs that are included in the changes.
    Write-Output "Creating a GitHub release"
    $Command = {gh api /repos/$OrgName/$RepoName/releases -X POST -f "tag_name=$Tag" -F "generate_release_notes=true" -f "name=Version $Tag"}
    if ($DryRun -eq $False) {
        & $Command
    }
    else {
        Write-Output "Dry run - not executing the following: $Command"
    }

}
finally {
    
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
