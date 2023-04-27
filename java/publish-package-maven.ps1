param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$MavenSettings,
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

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $Version = mvn org.apache.maven.plugins:maven-help-plugin:3.1.0:evaluate -Dexpression="project.version" -q -DforceStdout
    Write-Output "Version: '$Version'"

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

    Write-Output "Writing PGP File"
    Set-Content -Path $JavaPGPFile -Value $JavaPGP


    echo $JavaGpgKeyPassphrase | gpg --import --batch --yes --passphrase-fd 0 $JavaPGPFile

    Write-Output "Deploying to Nexus staging"
    
    mvn deploy -DdeployOnly -DskipTests -s $settingsFile --no-transfer-progress "-Dhttps.protocols=TLSv1.2" -Dskippackagesign=false "-Dgpg.passphrase=$JavaGpgKeyPassphrase" -Dkeystore=$CodeSigningCertFile -Dalias=$CodeSigningCertAlias -Dkeypass=$CodeSigningCertPassword -Dkeystorepass=$CodeSigningCertPassword

    if ($($Version.EndsWith("SNAPSHOT")) -eq $False) {

        Write-Output "Releasing from Nexus to Maven central"
        #mvn nexus-staging:release
    
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
