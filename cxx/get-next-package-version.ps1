param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$VariableName
)
$ErrorActionPreference = "Stop"

./steps/get-next-package-version.ps1 -RepoName $RepoName -VariableName GitVersion

Set-Variable -Scope 1 -Name $VariableName -Value $GitVersion.MajorMinorPatch
