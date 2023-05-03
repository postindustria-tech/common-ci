
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Configuration = "Release",
    # TODO add arch
    [string]$ProjectDir = ".",
    [Parameter(Mandatory=$true)]
    [string]$ResultName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    ## TODO MSBuild framework

}
finally {
   
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
