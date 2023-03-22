param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Branch
)

$Url = "https://github.com/51degrees/$RepoName"
$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Cloning '$Url'"
git clone $Url

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

$branches = $(git branch -a --format "%(refname)")

if ($branches.Contains("refs/remotes/$Branch")) {
    Write-Output "Checking out branch '$Branch'"
    git checkout $Branch
}
else {
    Write-Output "Creating new branch '$Branch'"
    git checkout -b $Branch
}

Write-Output "Leaving '$RepoPath'"
Pop-Location
