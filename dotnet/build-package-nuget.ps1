
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release",
    [string]$Arch = "x64",
    [string]$Version,
    [string]$SolutionName,
    # Regex pattern to filter out projects that will not be published as a package 
    [string]$SearchPattern = "^(?!.*Test)Project\(.*csproj",
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
   
    $Projects = Get-Content "$SolutionName" |
    Select-String $SearchPattern |
        ForEach-Object {
            $projectParts = $_ -Split '[,=]' | ForEach-Object { $_.Trim('[ "{}]') };
            New-Object PSObject -Property @{
                Name = $projectParts[1];
                File = $projectParts[2];
                Guid = $projectParts[3]
            }
    }
    foreach($Project in $Projects){
        dotnet pack $Project.File -o "$PackagesFolder" -c $Configuration /p:Platform=$Arch /p:PackageVersion=$Version /p:BuiltOnCI=true
    }
    nuget sign "$PackagesFolder\*.nupkg" -CertificatePath $CertPath -CertificatePassword $CodeSigningCertPassword -Timestamper http://timestamp.digicert.com

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
