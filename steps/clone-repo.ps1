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

if ("" -ne $Branch) {

    Write-Output "Entering '$RepoPath'"
    Push-Location $RepoPath

    try {

        $branches = $(git branch -a --format "%(refname)")

        if ($branches.Contains("refs/remotes/$Branch")) {

            Write-Output "Checking out branch '$Branch'"
            git checkout $Branch

        }
        else {

            Write-Output "Creating new branch '$Branch'"
            git checkout -b $Branch

        }

    }
    finally {
        
        Write-Output "Leaving '$RepoPath'"
        Pop-Location

    }
}
