param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = "."
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

Push-Location $RepoName
try {
    mvn -B install -f pom.xml -DXmx2048m -DskipTests --no-transfer-progress '-Dhttps.protocols=TLSv1.2' -DfailIfNoTests=false
} finally {
    Pop-Location
}
