
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Configuration = "Release",
    # TODO add arch
    [string]$ProjectDir = ".",
    [Parameter(Mandatory=$true)]
    [string]$ResultName,
    $Options
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    ## TODO output is no longer correct
    Write-Output "Building core $Configuration"
    dotnet build $Options $ProjectDir

}
finally {

    Write-Output "Setting '`$$ResultName'"
    Set-Variable -Name $ResultName -Value $(0 -eq $LASTEXITCODE) -Scope 1
    
    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}