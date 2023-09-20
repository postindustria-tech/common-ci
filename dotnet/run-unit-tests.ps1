
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release",
    [string]$Arch = "x64",
    [string]$BuildMethod="dotnet",
    [string]$DirNameFormat = "*bin*",
    [string]$Filter,
    [string]$OutputFolder = "unit"
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$TestResultPath = [IO.Path]::Combine($RepoPath, "test-results", $OutputFolder, $Name)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

$ok = $true

try {

    $skipPattern = "*performance*"
    Write-Output "Testing '$Name'"
    if ($BuildMethod -eq "dotnet"){
        Write-Output "Looking for '$Filter' in directories like '$DirNameFormat'"
        Get-ChildItem -Path $RepoPath -Recurse -File | ForEach-Object {
            if (($_.DirectoryName -like $DirNameFormat -and $_.Name -notlike $skipPattern) -and ($_.Name -match "$Filter")) {
                Write-Output "Testing Assembly: '$_'"
                dotnet test $_.FullName --results-directory $TestResultPath --blame-crash -l "trx" || $($script:ok = $false)
            }
        }
    }
    else{

        Get-ChildItem -Path $RepoPath -Recurse -File | ForEach-Object {
            if (($_.DirectoryName -like "*\bin\*" -and $_.Name -notlike $skipPattern) -and ($_.Name -match "$Filter")) {
                Write-Output "Testing Assembly: '$_'"
                & vstest.console.exe $_.FullName /Logger:trx /ResultsDirectory:$TestResultPath || $($script:ok = $false)
            }
        }
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $ok ? 0 : 1
