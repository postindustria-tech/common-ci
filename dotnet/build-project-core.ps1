
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    $Options
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Building $($Options.Name)"
    $BuildArgs = @()
    if ($Null -ne $Options.Configuration) {
        $BuildArgs += "-c", $Options.Configuration
    }
    dotnet build $BuildArgs $ProjectDir

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE