param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Tag
)
$RepoPath = [IO.Path]::Combine($pwd, $RepoName)


Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Tagging with '$Tag'"
    git tag $Tag

    Write-Output "Pushing tag"
    git push origin $Tag

    Write-Output "Creating a GitHub release"
    hub api /repos/51degrees/$RepoName/releases -X POST -f "tag_name=$Tag" -F "generate_release_notes=true" -f "name=Version $Tag"

}
finally {
    
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}