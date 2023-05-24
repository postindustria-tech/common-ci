
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release",
    [string]$Arch = "x64",
    [string]$BuildMethod="dotnet",
    [string]$Filter
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $skipPattern = "*performance*"
    Write-Output "Testing '$Name'"
    if ($BuildMethod -eq "dotnet"){
        Get-ChildItem -Path $RepoPath -Recurse -File | ForEach-Object {
            if (($_.DirectoryName -like "*\bin\*" -and $_.Name -notlike $skipPattern) -and ($_.Name -match "$Filter")) {
                Write-Output "Testing Assembly: '$_'"
                dotnet test $_.FullName --results-directory "test-results/unit/$Name" --blame-crash -l "trx" -c $Configuration --no-build /p:Platform=$Arch
            }
        }
    }
    else{

        Get-ChildItem -Path $RepoPath -Recurse -File | ForEach-Object {
            if (($_.DirectoryName -like "*\bin\*" -and $_.Name -notlike $skipPattern) -and ($_.Name -match "$Filter")) {
                Write-Output "Testing Assembly: '$_'"
                & vstest.console.exe $_.FullName /Logger:trx /ResultsDirectory:"./test-results/unit/" 
            }
        }
    } 

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
