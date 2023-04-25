
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    Write-Output "Checking if update is required"
    $Tags = $(git tag --list)

    foreach ($Tag in $Tags) {

        if ($Tag -eq $Version) {

            Write-Output "Version '$Version' already present, no update needed"
            # This is not treated as an error, but an indication that the result
            # is false.
            exit 1

        }

    }

    exit 0
    
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

