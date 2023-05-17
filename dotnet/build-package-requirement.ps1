param(
    [string]$ProjectDir = ".",
    [string]$Configuration = "CoreRelease",
    [string]$RepoName
)

./cxx/build-project.ps1 -RepoName $RepoName -ProjectDir $ProjectDir -Configuration $Configuration

exit $LASTEXITCODE