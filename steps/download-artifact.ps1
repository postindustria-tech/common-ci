
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    $RunId,
    [Parameter(Mandatory=$true)]
    [string]$ArtifactName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

$Artifacts = $(hub api /repos/51degrees/$RepoName/actions/runs/$RunId/artifacts | ConvertFrom-Json).artifacts

foreach ($Artifact in $Artifacts) {
    if ($Artifact.name -eq $ArtifactName) {
        Write-Output "Downloading '$ArtifactName'"

        Invoke-WebRequest -Uri $Artifact.archive_download_url -Headers @{"Authorization" = "Bearer $GitHubToken"} -Outfile "$ArtifactName.zip"
        exit 0
    }
}

Write-Output "Artifact '$ArtifactName' not found for run '$RunId'"
exit 1
