
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    #[Parameter(Mandatory=$true)]
    [string]$ApiKey
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Releasing package for '$Name'"

    $packageDirectory = [IO.Path]::Combine((Get-Item $RepoPath).Parent.FullName, "package")
    $packagePaths = Get-ChildItem -Path $packageDirectory -Filter "*.nupkg" -File | ForEach-Object { $_.FullName }
    $packageString = $packagePaths -join ' '

    # This is set to internal feed for now for testing.
    dotnet nuget push --source "https://51degrees.pkgs.visualstudio.com/_packaging/pipeline-insider/nuget/v3/index.json" --api-key az $packageString

    # This releases the package to nuget publicly uncomment when ready. 
    #dotnet nuget push $packageString --source https://api.nuget.org/v3/index.json --api-key $ApiKey


}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
