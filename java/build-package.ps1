
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name,
    [string]$Version
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

# Path for the locally installed packages from which they will be uploaded to artifacts
$PackagePath = "$RepoPath/package"

$MavenLocalRepoPath = mvn help:evaluate -Dexpression="settings.localRepository" -q -DforceStdout

Write-Output $MavenLocalRepoPath

$MavenLocal51DPath = [IO.Path]::Combine($MavenLocalRepoPath, "com", "51degrees")

Write-Output $MavenLocal51DPath

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    if(![string]::IsNullOrWhitespace($Version)){
        Write-Output "Setting package version to '$Version'"
        mvn versions:set -DnewVersion="$Version"
    }

    Write-Output "Building '$Name'"
    mvn install -f pom.xml -DXmx2048m -DskipTests --no-transfer-progress '-Dhttps.protocols=TLSv1.2' -DfailIfNoTests=false

    New-Item -Path $PackagePath -ItemType Directory -Force 
    $LocalRepoPackages = Get-ChildItem -Path $MavenLocal51DPath
    Copy-Item -Path $LocalRepoPackages -Destination "$PackagePath"

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
