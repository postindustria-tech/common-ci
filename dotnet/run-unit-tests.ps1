
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Configuration = "Release",
    [string]$Arch,
    [string]$ProjectDir = ".",
    [Parameter(Mandatory=$true)]
    [string]$ResultName,
    $Options
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $TestArgs = $ProjectDir, "-r", "output", "--blame-crash", "-l", "trx"

    $TestArgs += $Options
    
    dotnet test $TestArgs

}
finally {

    Write-Output "Setting '`$$ResultName'"
    Set-Variable -Name $ResultName -Value $(0 -eq $LASTEXITCODE) -Scope 1

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

