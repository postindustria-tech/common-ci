
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name,
    [string]$Version
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    if(![string]::IsNullOrWhitespace($Version)){
        Write-Output "Setting package version to '$Version'"
        mvn versions:set -DnewVersion="$Version"
    }
    
    Write-Output "Building '$Name'"
    mvn install -f pom.xml -DXmx2048m -DskipTests --no-transfer-progress '-Dhttps.protocols=TLSv1.2' -DfailIfNoTests=false

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
