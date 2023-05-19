
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [bool]$DryRun = $False
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    $CurrentBranch = $(git rev-parse --abbrev-ref HEAD)
    
    Write-Output "Getting PRs from '$CurrentBranch' to 'main'"
    $Prs = $(hub pr list -b main -h $CurrentBranch --format "%I%n")

    Write-Output "There are '$($Prs.Count)' PRs"

    if ($Prs.Count -eq 0) {
        Write-Output "Creating pull request"
        $Command = "hub pull-request --no-edit --message $Message"
        if ($DryRun -eq $False) {
            Invoke-Expression $Command
        }
        else {
            Write-Output "Dry run - not executing the following: $Command"
        }
    }
    else {
        Write-Output "A PR already exists for this branch."
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

