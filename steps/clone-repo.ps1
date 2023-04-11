param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Branch
)

. ./constants.ps1

$Url = "$BaseGitUrl$RepoName"
$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Cloning '$Url'"
git clone $Url


Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    if ("" -ne $Branch) {

        $branches = $(git branch -a --format "%(refname)")

        if ($branches.Contains("refs/remotes/origin/$Branch")) {

            Write-Output "Checking out branch '$Branch'"
            git checkout $Branch

        }
        else {

            Write-Output "Creating new branch '$Branch'"
            git checkout -b $Branch

        }
    }
    
    Write-Output "Checking out submodules"
    git submodule update --init --recursive

}
finally {
    
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
