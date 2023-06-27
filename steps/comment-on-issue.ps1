param(
    [string]$RepoName,
    [string]$OrgName,
    [int]$Id,
    [string]$Message,
    [string]$GitHubToken
)

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

hub api /repos/$OrgName/$RepoName/issues/$Id/comments -X POST -f `"body=$Message`"
