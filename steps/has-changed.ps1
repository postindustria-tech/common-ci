
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    Write-Output "Checking Changes"
    $changes = $(git status -s)

    Write-Output "There are '$($changes.count)' changes:"
    foreach ($change in $changes) {
        Write-Output "`t$change"
    }

    if ($changes.count -gt 0) {
        exit 0
    }
    else {
        exit 1
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
