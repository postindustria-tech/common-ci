
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [string]$ProjectDir = "."
    
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Setting Version to $Version"
    mvn versions:set -DnewVersion="$Version"-SNAPSHOT -DprocessAllModules

    Write-Output "Building Packages"
    mvn package -DskipTests -f pom.xml -DXmx2048m --no-transfer-progress

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location
}

exit $LASTEXITCODE