param (
    [Parameter(Mandatory=$true)]
    [string]$VariableName,
    [string]$RepoName,
    [string]$ProjectDir = "."
)

$GitVersionConfigPath = [IO.Path]::Combine($pwd, "java", "gitversion.yml")

./steps/get-next-package-version.ps1 -RepoName $RepoName -VariableName $VariableName -GitVersionConfigPath $GitVersionConfigPath

$assemblySemVer = (Get-Variable -Name $VariableName -Scope Global).Value
Set-Variable -Name $VariableName -Value $assemblySemVer -Scope Global

exit $LASTEXITCODE


