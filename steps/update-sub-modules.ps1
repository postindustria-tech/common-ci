
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

Write-Output "Cloning Submodules"
git submodule update --init --recursive

Write-Output "Updating Submodules"
git submodule foreach 'git checkout main && git pull origin'

Write-Output "Leaving '$RepoPath'"
Pop-Location