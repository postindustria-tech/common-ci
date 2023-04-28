param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$MavenSettings,
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Setting version to '$Version'"
    mvn versions:set -DnewVersion="$Version"

    $settingsFile = "stagingsettings.xml"

    Write-Output "Writing Settings File"
    $SettingsContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($MavenSettings))
    Set-Content -Path $settingsFile -Value $SettingsContent

    # Set file names
    $CodeSigningCertFile = "51Degrees Private Code Signing Certificate.pfx"
    $JavaPGPFile = "Java Maven GPG Key Private.pgp"

    Write-Output "Writing PFX File"
    $CodeCertContent = [System.Convert]::FromBase64String($CodeSigningCert)
    Set-Content $CodeSigningCertFile -Value $CodeCertContent -AsByteStream
    $CertPath = [IO.Path]::Combine($RepoPath, $CodeSigningCertFile)

    Write-Output "Writing PGP File"
    Set-Content -Path $JavaPGPFile -Value $JavaPGP

    echo $JavaGpgKeyPassphrase | gpg --import --batch --yes --passphrase-fd 0 $JavaPGPFile

    Write-Output "Deploying to Nexus staging"
    
    mvn nexus-staging:deploy-staged
        -s $settingsFile  `
        -f pom.xml `
        -DXmx2048m `
        -DskipTests `
        --no-transfer-progress `
        "-Dhttps.protocols=TLSv1.2" `
        "-DfailIfNoTests=false" 

    if ($($Version.EndsWith("SNAPSHOT")) -eq $False) {

        Write-Output "Releasing from Nexus to Maven central"
        #mvn nexus-staging:release
    
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
