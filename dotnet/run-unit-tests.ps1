
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    $Options
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Testing $($Options.Name)"

    $TestArgs = $ProjectDir, "-r", "output", "--blame-crash", "-l", "trx;logfilename=$($Options.Name).trx"

    if ($Null -ne $Options.Configuration) {
        $TestArgs += "-c", $Options.Configuration
    }
    if ($Null -ne $Options.Arch) {
        $TestArgs += "-a", $Options.Arch
    }
    
    dotnet test $TestArgs

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE