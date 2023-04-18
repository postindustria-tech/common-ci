param (
    [Parameter(Mandatory=$true)]
    [string]$VariableName,
    [string]$RepoName,
    [string]$ProjectDir = "."
)

try{

    ./steps/get-next-package-version.ps1 -RepoName $RepoName -VariableName $VariableName

    Set-Variable -Name $VariableName -Value $GitVersion.AssemblySemVer -Scope Global
}
finally {

    Write-Output "Leaving '$RepoPath'"
    

}

exit $LASTEXITCODE


