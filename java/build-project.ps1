
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    Write-Host $env:JAVA_HOME_8_X64
    
    # Set the JAVA_HOME environment variable
    $env:JAVA_HOME = $env:JAVA_HOME_8_X64

    # Add the Java binary directory to the system PATH
    $env:Path += ";" + "$env:JAVA_HOME\bin"

    # Verify that the correct version of Java is being used
    java -version

    #-Dhttps.protocols=TLSv1.2
    Write-Output "Building '$Name'"
    mvn compile -f pom.xml -DXmx2048m --no-transfer-progress

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE