param(
    [string]$RepoName,
    [string]$OrgName,
    [int]$Id,
    [string]$Message,
    [string]$GitHubToken
)

hub api /repos/$OrgName/$RepoName/issues/$Id/comments -X POST -f `"body=$Message`"
