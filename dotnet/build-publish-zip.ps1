param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [string]$Project = ".",
    [string]$Platform = "-r win-x64"
)

$packagesDir = New-Item -ItemType directory -Path package -Force

Push-Location $RepoName
try {
    dotnet publish $Project --nologo --sc -c Release $Platform -o publish /p:Version=$Version || $(throw "dotnet publish failed")
    Compress-Archive -Path publish/* -DestinationPath $packagesDir/$RepoName-$Version.zip
} finally {
    Pop-Location
}
