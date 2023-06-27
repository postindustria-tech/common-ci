param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$VariableName
)

./steps/get-next-package-version.ps1 -RepoName $RepoName -VariableName $VariableName -GitVersionConfigPath (Join-Path python gitversion.yml)

$assemblySemVer = (Get-Variable -Name $VariableName).Value.AssemblySemVer
Set-Variable -Name $VariableName -Value $assemblySemVer -Scope Global

exit $LASTEXITCODE
