
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
    [string]$CodeSigningCertPassword,
    [Parameter(Mandatory=$true)]
    [string]$MavenSettings
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$MavenLocalRepoPath = mvn help:evaluate -Dexpression="settings.localRepository" -q -DforceStdout

Write-Output $MavenLocalRepoPath

$MavenLocal51DPath = [IO.Path]::Combine($MavenLocalRepoPath, "com", "51degrees")

$NexusLocalStaging51DPath = Join-Path (Split-Path $MavenLocalRepoPath -Parent) "deferred"


Write-Output $MavenLocal51DPath

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
      
    Write-Output "Setting package version to '$Version'"
    mvn versions:set -DnewVersion="$Version"

    # Set file names
    $CodeSigningCertFile = "51Degrees Private Code Signing Certificate.pfx"
    $JavaPGPFile = "Java Maven GPG Key Private.pgp"  
    $SettingsFile = "stagingsettings.xml"

    Write-Output "Writing Settings File"
    $SettingsContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($MavenSettings))
    Set-Content -Path $SettingsFile -Value $SettingsContent
    $SettingsPath = [IO.Path]::Combine($RepoPath, $SettingsFile)


    Write-Output "Writing PFX File"
    $CodeCertContent = [System.Convert]::FromBase64String($CodeSigningCert)
    Set-Content $CodeSigningCertFile -Value $CodeCertContent -AsByteStream
    $CertPath = [IO.Path]::Combine($RepoPath, $CodeSigningCertFile)

    Write-Output "Writing PGP File"
    Set-Content -Path $JavaPGPFile -Value $JavaPGP

    echo $JavaGpgKeyPassphrase | gpg --import --batch --yes --passphrase-fd 0 $JavaPGPFile

    Write-Output "Building '$Name'"
    mvn deploy `
        -s $SettingsPath `
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
        "-Dkeystorepass=$CodeSigningCertPassword" `
        "-DskipRemoteStaging=true"

    Write-Output "Maven Local 51d Repo:"
    ls $MavenLocal51DPath

    $PackagePath = "$RepoPath/package"
    
    # Create the "package" folder if it doesn't exist
    New-Item -ItemType Directory -Path $PackagePath -Force

    Copy-Item -Path $MavenLocal51DPath -Destination $RepoPath -Recurse
    Rename-Item -Path $RepoPath/51degrees -NewName "local"


    Copy-Item -Path $NexusLocalStaging51DPath -Destination $RepoPath -Recurse
    Rename-Item -Path "$RepoPath/deferred" -NewName "nexus"

    # Move the "local" folder to the "package" folder
    Move-Item -Path "$RepoPath/local"  -Destination $PackagePath

    # Move the "nexus" folder to the "package" folder
    Move-Item -Path "$RepoPath/nexus" -Destination $PackagePath

    ls "$RepoPath/package"

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
