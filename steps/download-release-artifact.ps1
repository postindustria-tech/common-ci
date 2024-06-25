param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [Parameter(Mandatory=$true)]
    [string]$Version
)

Write-Output  "Repo Context $OrgName/$RepoName"
# Set the repository context for the GitHub CLI
$RepoContext = "$OrgName/$RepoName"

# Download the release assets using the GitHub CLI
Write-Output  "Downloading the Artifact"
gh release download --repo $RepoContext "v$Version/*" --pattern "*.zip"

# Unzip Artifact
Write-Output  "Unzipping the Artifact"
$ZipFiles = Get-ChildItem -Filter *.zip
foreach ($file in $ZipFiles) {
    Expand-Archive -Path $file.FullName -DestinationPath "./extracted-artifact"
}

# Output the path of the extracted artifact(s)
Write-Output  "OutputPath = ./extracted-artifact"
Get-ChildItem -Path "./extracted-artifact"

# set path for other jobs to use
echo "::set-output name=artifact_path::./extracted-artifact"
