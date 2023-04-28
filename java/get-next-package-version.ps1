param (
    [Parameter(Mandatory=$true)]
    [string]$VariableName,
    [string]$RepoName,
    [string]$ProjectDir = "."
)

$GitVersionConfigPath = [IO.Path]::Combine($pwd, "java", "gitversion.yml")

./steps/get-next-package-version.ps1 -RepoName $RepoName -VariableName $VariableName -GitVersionConfigPath $GitVersionConfigPath 

Write-Output "Variable Name: '$VariableName'"

Set-Variable -Name $VariableName -Value $GitVersion.AssemblySemVer -Scope Global

exit $LASTEXITCODE


