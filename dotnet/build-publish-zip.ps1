param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [string]$Project = ".",
    [string]$Platform = "win-x64",
    [string]$ZipName = $RepoName
)

$packagesDir = New-Item -ItemType directory -Path package -Force
$PublishDir = "publish-$ZipName"

Push-Location $RepoName
try {
    dotnet publish $Project --nologo --sc -c Release -r $Platform -o $PublishDir /p:Version=$Version || $(throw "dotnet publish failed")
    Compress-Archive -Path $PublishDir/* -DestinationPath $packagesDir/$ZipName-$Version.zip
} finally {
    Pop-Location
}
