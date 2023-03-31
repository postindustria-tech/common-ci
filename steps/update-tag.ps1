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

}
finally {
    
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}