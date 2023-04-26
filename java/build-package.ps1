
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name,
    [string]$Version,
    [string]$ExtraArgs
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$MavenLocalRepoPath = mvn help:evaluate -Dexpression="settings.localRepository" -q -DforceStdout

Write-Output $MavenLocalRepoPath

$MavenLocal51DPath = [IO.Path]::Combine($MavenLocalRepoPath, "com", "51degrees")

Write-Output $MavenLocal51DPath

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Setting package version to '$Version'"
    mvn versions:set -DnewVersion="$Version"

    Write-Output "Building '$Name'"
    mvn install -f pom.xml -DXmx2048m -DskipTests --no-transfer-progress '-Dhttps.protocols=TLSv1.2' -DfailIfNoTests=false $ExtraArgs

    $LocalRepoPackages = Get-ChildItem -Path $MavenLocal51DPath
    Write-Output "Maven Local 51d Repo:"
    ls $MavenLocal51DPath

    Copy-Item -Path $MavenLocal51DPath -Destination $RepoPath -Recurse
    Rename-Item -Path $RepoPath/51degrees -NewName "package"
    Write-Output "Package after:"
    ls "$RepoPath/package"


}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
