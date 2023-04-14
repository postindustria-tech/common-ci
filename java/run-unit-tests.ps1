
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
    
    #-Dhttps.protocols=TLSv1.2
    Write-Output "Building '$Name'"
    mvn clean test -Dtest="!**/*Integration*,!**/*PerformanceTest*" -f pom.xml -DXmx2048m --no-transfer-progress -DfailIfNoTests=false

    # Copy the test results into the test-results folder
    Get-ChildItem -Path . -Directory -Depth 1 | 
    Where-Object { Test-Path "$($_.FullName)\pom.xml" } | 
    ForEach-Object { 
        $targetDir = "$($_.FullName)\target\surefire-reports"
        $destDir = ".\test-results\unit"
        if(!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir }
        if(Test-Path $targetDir) {
            Get-ChildItem -Path $targetDir | 
            Where-Object { $_.Name -notlike "*Integration*" -and $_.Name -notlike "*Performance*"  } |
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