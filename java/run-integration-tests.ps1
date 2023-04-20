
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName, $ProjectDir)


try {
    Write-Output "Cloning device-detection-java-examples"
    ./steps/clone-repo.ps1 -RepoName "device-detection-java-examples"
    
    Write-Output "Moving TAC file for examples"
    Move-Item $RepoPath/TAC-HashV41.hash  ../b/device-detection-data/TAC-HashV41.hash

    Write-Output "Entering device-detection-examples directory"
    Push-Location device-detection-java-examples 

    Write-Output "Setting examples device-detection package dependency to version" $GitVersion
    mvn versions:set-property -Dproperty="device-detection.version" -DnewVersion=$GitVersion 

    Write-Output "Testing Examples"
    mvn clean test

    Write-Output "Copying test results"
    # Copy the test results into the test-results folder
    Get-ChildItem -Path . -Directory -Depth 1 | 
    Where-Object { Test-Path "$($_.FullName)\pom.xml" } | 

    ForEach-Object { 
        $targetDir = "$($_.FullName)\target\surefire-reports"
        $destDir = "..\device-detection-java-test\test-results\integration"
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
