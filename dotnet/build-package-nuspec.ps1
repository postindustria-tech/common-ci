
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Name = "Release",
    [string]$Configuration = "Release",
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [string]$NuspecPath,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningCert,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningCertPassword
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$PackagesFolder = [IO.Path]::Combine($pwd, "package")
$CodeSigningCertFile = "51Degrees Private Code Signing Certificate.pfx"
$CertPath = [IO.Path]::Combine($RepoPath, $CodeSigningCertFile)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    Write-Output "Writing PFX File"
    $CodeCertContent = [System.Convert]::FromBase64String($CodeSigningCert)
    Set-Content $CodeSigningCertFile -Value $CodeCertContent -AsByteStream

    Write-Output "Building package for '$Name'"
   
    nuget pack $NuspecPath -NonInteractive -OutputDirectory "$PackagesFolder" -Properties config=$Configuration -version $Version
    nuget sign -Overwrite "$PackagesFolder\*.nupkg" -CertificatePath $CertPath -CertificatePassword $CodeSigningCertPassword -Timestamper http://timestamp.digicert.com

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
