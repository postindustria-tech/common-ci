
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$VariableName = "Version"
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    
    Write-Output "Installing gitversion"
    dotnet tool install --global GitVersion.Tool --version 5.*

    Write-Output "Setting gitversion as '$VariableName'"
    Set-Variable -Name $VariableName -Value $(dotnet-gitversion | ConvertFrom-Json) -Scope 1

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

