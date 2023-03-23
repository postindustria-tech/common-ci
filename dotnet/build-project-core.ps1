
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Configuration = "Release",
    # TODO add arch
    [string]$ProjectDir = ".",
    [Parameter(Mandatory=$true)]
    [string]$ResultName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    dotnet build -c $Configuration $ProjectDir

}
finally {

    Write-Output "Setting '`$$ResultName'"
    Set-Variable -Name $ResultName -Value $(0 -eq $LASTEXITCODE) -Scope 1
    
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}