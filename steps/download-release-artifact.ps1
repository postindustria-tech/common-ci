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
gh release download --repo $RepoContext "$Version" --pattern "*.zip"

# Write out the path to the artifact
$artifactPath = Get-ChildItem -path "./" -Filter "*-$Version.zip"

# Output the path(s) to the artifact(s)
if ($artifactPath.Count -gt 1) {
    foreach ($path in $artifactPath) {
        Write-Output "Artifact: $($path.FullName)"
    }
} else {
    Write-Output "Artifact: $($artifactPath.FullName)"
}

