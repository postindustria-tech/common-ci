
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [string]$ExtraArgs,
    [Parameter(Mandatory=$true)]
    [string]$JavaGpgKeyPassphrase,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningCert,
    [Parameter(Mandatory=$true)]
    [string]$JavaPGP,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningCertAlias,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningCertPassword
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$MavenLocalRepoPath = mvn help:evaluate -Dexpression="settings.localRepository" -q -DforceStdout

Write-Output $MavenLocalRepoPath

$MavenLocal51DPath = [IO.Path]::Combine($MavenLocalRepoPath, "com", "51degrees")

Write-Output $MavenLocal51DPath

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
      
    Write-Output "Setting package version to '$Version'"
    mvn versions:set -DnewVersion="$Version"

    # Set file names
    $settingsFile = "stagingsettings.xml"
    $CodeSigningCertFile = "51Degrees Private Code Signing Certificate.pfx"
    $JavaPGPFile = "Java Maven GPG Key Private.pgp"

    Write-Output "Writing Settings File"
    $SettingsContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($MavenSettings))
    Set-Content -Path $settingsFile -Value $SettingsContent

    Write-Output "Writing PFX File"
    $CodeCertContent = [System.Convert]::FromBase64String($CodeSigningCert)
    Set-Content $CodeSigningCertFile -Value $CodeCertContent -AsByteStream
    $CertPath = [IO.Path]::Combine($RepoPath, $CodeSigningCertFile)

    Write-Output "Writing PGP File"
    Set-Content -Path $JavaPGPFile -Value $JavaPGP

    echo $JavaGpgKeyPassphrase | gpg --import --batch --yes --passphrase-fd 0 $JavaPGPFile

    Write-Output "Building '$Name'"
    mvn install `
        $ExtraArgs `
        -f pom.xml `
        -DXmx2048m `
        -DskipTests `
        --no-transfer-progress `
        "-Dhttps.protocols=TLSv1.2" `
        "-DfailIfNoTests=false" `
        "-Dskippackagesign=false" `
        "-Dgpg.passphrase=$JavaGpgKeyPassphrase" `
        "-Dkeystore=$CertPath" `
        "-Dalias=$CodeSigningCertAlias" `
        "-Dkeypass=$CodeSigningCertPassword" `
        "-Dkeystorepass=$CodeSigningCertPassword"

    $LocalRepoPackages = Get-ChildItem -Path $MavenLocal51DPath
    Write-Output "Maven Local 51d Repo:"
    ls $MavenLocal51DPath

    Copy-Item -Path $MavenLocal51DPath -Destination $RepoPath -Recurse
    Rename-Item -Path $RepoPath/51degrees -NewName "package"
    Write-Output "Package after:"
    ls "$RepoPath/package"


}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
