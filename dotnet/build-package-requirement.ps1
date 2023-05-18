param(
    [string]$ProjectDir = ".",
    [string]$Configuration = "CoreRelease",
    [string]$RepoName,
    [string]$Arch
)

./cxx/build-project.ps1 -RepoName $RepoName -ProjectDir $ProjectDir -Configuration $Configuration -Arch $Arch

exit $LASTEXITCODE