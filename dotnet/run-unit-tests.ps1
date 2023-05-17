
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release",
    [string]$Arch = "x64",
    [string]$BuildMethod="msbuild"
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Testing '$Name'"
    if ($BuildMethod -eq "dotnet"){

        dotnet test $ProjectDir --results-directory "test-results/unit/$Name"--filter "FullyQualifiedName!~Performance&FullyQualifiedName!~Integration" --blame-crash -l "trx" -c $Configuration -a $Arch

    }
    else{

        Get-ChildItem -Path $RepoPath -Filter "*Tests.dll" -Recurse -File | ForEach-Object {
            if ($_.DirectoryName -like "*\bin\*") {
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
