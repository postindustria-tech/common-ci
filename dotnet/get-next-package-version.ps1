
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$VariableName = "Version"
)

./steps/get-next-package-version.ps1 -RepoName $RepoName -VariableName "GitVersion"

Write-Output "Setting version '$($GitVersion.FullSemVer)' as '$VariableName'"
Set-Variable -Name $VariableName $GitVersion.FullSemVer -Scope 1
