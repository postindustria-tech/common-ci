
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    Write-Output "Updating dependencies. Patch version only"
    mvn versions:update-properties -DallowMinorUpdates=false

}
finally {
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE