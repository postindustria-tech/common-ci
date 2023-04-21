
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Windows_Java_8",
    [string]$Version = "0.0.0",
    [Hashtable]$Keys
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)


try {
    Write-Output "Cloning device-detection-java-examples"
    ./steps/clone-repo.ps1 -RepoName "device-detection-java-examples"
    
    Write-Output "Moving TAC file for examples"
    $TacFile = [IO.Path]::Combine($RepoPath, "TAC-HashV41.hash") 

    Move-Item $TacFile device-detection-java-examples/device-detection-data/TAC-HashV41.hash

    Write-Output "Entering device-detection-examples directory"
    Push-Location device-detection-java-examples 

    Write-Output "Setting examples device-detection package dependency to version '$Version'"
    mvn versions:set-property -Dproperty="device-detection.version" "-DnewVersion=$Version"

    Write-Output "Testing Examples"
    Write-Output " mvn clean test '-DTestResourceKey=$($Keys.TestResourceKey)' '-DLicenseKey=$($Keys.DeviceDetection)'"
    mvn clean test "-DTestResourceKey=$($Keys.TestResourceKey)" "-DLicenseKey=$($Keys.DeviceDetection)"

    Write-Output "Copying test results"
    # Copy the test results into the test-results folder
    Get-ChildItem -Path . -Directory -Depth 1 | 
    Where-Object { Test-Path "$($_.FullName)\pom.xml" } | 

    ForEach-Object { 
        $targetDir = "$($_.FullName)\target\surefire-reports"
        $destDir = "..\de-detection-java-test\test-results\integration"
        if(!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir }
        if(Test-Path $targetDir) {
            Get-ChildItem -Path $targetDir |
            ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $destDir
            }
        }
    }
}

finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
