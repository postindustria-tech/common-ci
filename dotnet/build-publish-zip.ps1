param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

$packagesDir = New-Item -ItemType directory -Path package -Force

Push-Location $RepoName
try {
	dotnet publish --nologo --sc -c Release -r win-x64 -o publish || $(throw "dotnet publish failed")
	Compress-Archive -Path publish -DestinationPath $packagesDir/$RepoName.zip
} finally {
    Pop-Location
}
