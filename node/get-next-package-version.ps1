param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$VariableName
)

./steps/get-next-package-version.ps1 -RepoName $RepoName -VariableName $VariableName -GitVersionConfigPath (Join-Path node gitversion.yml)

$semVer = (Get-Variable -Name $VariableName).Value.SemVer
Set-Variable -Name $VariableName -Value $semVer -Scope Global

exit $LASTEXITCODE