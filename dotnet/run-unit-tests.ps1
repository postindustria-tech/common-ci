
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release",
    [string]$Arch = "x64",
    [string]$BuildMethod="dotnet",
    [string]$Filter,
    [string]$OutputFolder = "unit"
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$TestResultPath = [IO.Path]::Combine($RepoPath, "test-results", $OutputFolder, $Name)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $skipPattern = "*performance*"
    Write-Output "Testing '$Name'"
    if ($BuildMethod -eq "dotnet"){
        Get-ChildItem -Path $RepoPath -Recurse -File | ForEach-Object {
            if (($_.DirectoryName -like "*bin*" -and $_.Name -notlike $skipPattern) -and ($_.Name -match "$Filter")) {
                Write-Output "Testing Assembly: '$_'"
                dotnet test $_.FullName --results-directory $TestResultPath --blame-crash -l "trx"
            }
        }
    }
    else{

        Get-ChildItem -Path $RepoPath -Recurse -File | ForEach-Object {
            if (($_.DirectoryName -like "*\bin\*" -and $_.Name -notlike $skipPattern) -and ($_.Name -match "$Filter")) {
                Write-Output "Testing Assembly: '$_'"
                & vstest.console.exe $_.FullName /Logger:trx /ResultsDirectory:$TestResultPath
            }
        }
    } 

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
