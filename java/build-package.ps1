
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
    [string]$JavaPGP,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningKeyVaultName,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningKeyVaultUrl,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningKeyVaultClientId,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningKeyVaultTenantId,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningKeyVaultClientSecret,
    [Parameter(Mandatory=$true)]
    [string]$CodeSigningKeyVaultCertificateName,
    [Parameter(Mandatory=$true)]
    [string]$MavenSettings
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$PackagePath = [IO.Path]::Combine($pwd, "package")

if ($($Version.EndsWith("SNAPSHOT"))) {
    $NexusSubFolder = "deferred"
}
else{
    $NexusSubFolder = "staging"
}
$MavenLocalRepoPath = mvn help:evaluate -Dexpression="settings.localRepository" -q -DforceStdout

Write-Output $MavenLocalRepoPath

$MavenLocal51DPath = [IO.Path]::Combine($MavenLocalRepoPath, "com", "51degrees")

$NexusLocalStaging51DPath = Join-Path (Split-Path $MavenLocalRepoPath -Parent) $NexusSubFolder


Write-Output $MavenLocal51DPath

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    Write-Output "Setting package version to '$Version'"
    mvn versions:set -DnewVersion="$Version"

    # Set file names
    $JavaPGPFile = "Java Maven GPG Key Private.pgp"  
    $SettingsFile = "stagingsettings.xml"
    $JcaProviderJar = [IO.Path]::Combine($RepoPath, "jsign.jar")

    # Write the content to the files.
    Write-Output "Writing Settings File"
    $SettingsContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($MavenSettings))
    Set-Content -Path $SettingsFile -Value $SettingsContent
    $SettingsPath = [IO.Path]::Combine($RepoPath, $SettingsFile)

    $jcaDownloadLink = "https://github.com/ebourg/jsign/releases/download/6.0/jsign-6.0.jar"
    Write-Output "Downloading $jcaDownloadLink"
    curl -o $JcaProviderJar $jcaDownloadLink

    Write-Output "Writing PGP File"
    Set-Content -Path $JavaPGPFile -Value $JavaPGP

    # Import the pgp key 
    Write-Output $JavaGpgKeyPassphrase | gpg --import --batch --yes --passphrase-fd 0 $JavaPGPFile
    gpg --list-keys

    $CodeSigningKeyVaultAccessToken = az account get-access-token --resource "https://vault.azure.net" --tenant $CodeSigningKeyVaultTenantId | jq -r .accessToken

    Write-Output "Deploying '$Name' Locally"
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
        "-DkeyvaultJcaJar=$JcaProviderJar" `
        "-DkeyvaultVaultName=$CodeSigningKeyVaultName" `
        "-DkeyvaultUrl=$CodeSigningKeyVaultUrl" `
        "-DkeyvaultClientId=$CodeSigningKeyVaultClientId" `
        "-DkeyvaultTenant=$CodeSigningKeyVaultTenantId" `
        "-DkeyvaultClientSecret=$CodeSigningKeyVaultClientSecret" `
        "-DkeyvaultCertName=$CodeSigningKeyVaultCertificateName" `
        "-DkeyvaultAccessToken=$CodeSigningKeyVaultAccessToken" `
        "-DskipRemoteStaging=true"

    Write-Output "Maven Local 51d Repo:"
    Get-ChildItem $MavenLocal51DPath
    
    # Create the "package" folder if it doesn't exist
    New-Item -ItemType Directory -Path $PackagePath -Force

    Copy-Item -Path $MavenLocal51DPath -Destination $RepoPath -Recurse
    Rename-Item -Path $RepoPath/51degrees -NewName "local"


    Copy-Item -Path $NexusLocalStaging51DPath -Destination $RepoPath -Recurse
    Rename-Item -Path "$RepoPath/$NexusSubFolder" -NewName "nexus"

    # Move the "local" folder to the "package" folder
    Move-Item -Path "$RepoPath/local"  -Destination $PackagePath

    # Move the "nexus" folder to the "package" folder
    Move-Item -Path "$RepoPath/nexus" -Destination $PackagePath

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
