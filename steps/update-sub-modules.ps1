
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    $CurrentBranch = $env:GITHUB_REF_NAME ? $env:GITHUB_REF_NAME : 'main'

    Write-Output "Merging any changes from $CurrentBranch"
    git merge origin/$CurrentBranch

    Write-Output "Cloning Submodules"
    git submodule update --init --recursive

    Write-Output "Updating Submodules"
    git submodule foreach "git checkout $CurrentBranch && git pull origin"

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
