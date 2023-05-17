
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    $RunId,
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

$Artifacts = $(hub api /repos/51degrees/$RepoName/actions/runs/$RunId/artifacts | ConvertFrom-Json).artifacts

foreach ($Artifact in $Artifacts) {
    if ($Artifact.name -eq $Name) {
        Write-Output "Downloading '$Name'"

        Invoke-WebRequest -Uri $Artifact.archive_download_url -Headers @{"Authorization" = "Bearer $GitHubToken"} -Outfile "$Name.zip"
        exit 0
    }
}

Write-Output "Artifact '$Name' not found for run '$RunId'"
exit 1