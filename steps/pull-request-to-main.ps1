
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    $CurrentBranch = $(git rev-parse --abbrev-ref HEAD)
    
    Write-Output "Getting PRs from '$CurrentBranch' to 'main'"
    $Prs = $(hub pr list -b main -h $CurrentBranch)

    Write-Output "There are '$($Prs.Count)' PRs"

    if ($Prs.Count -eq 0) {
        Write-Output "Creating pull request"
        hub pull-request --no-edit --message $Message
    }
    else {
        Write-Output "A PR already exists for this branch."
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

