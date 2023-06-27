param(
    [string]$RepoName,
    [string]$OrgName,
    [int]$Id,
    [string]$Message
)

hub api /repos/OWNER/REPO/issues/$Id/comments -X POST -f `"body=$Message`"