param(
    [string]$ProjectDir = ".",
    [string]$Configuration = "CoreRelease",
    [string]$RepoName,
    [string]$Arch
)

if ($Arch -eq "x86"){
    $ExtraArgs = "-D32bit=on"
}

./cxx/build-project.ps1 -RepoName $RepoName -ProjectDir $ProjectDir -Configuration $Configuration -ExtraArgs $ExtraArgs

exit $LASTEXITCODE