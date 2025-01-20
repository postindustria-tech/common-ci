# 1) If the current HEAD commit is already tagged - return the existing tag.
# 2) Otherwise, find the closest tag reachable from the HEAD.
# 3) If it is a single tag of that commit - return it with the last version component increased.
# 4) Otherwise, return the biggest version-sorted tag of that commit with the last version component increased.

param (
    [Parameter(Mandatory)][string]$RepoName,
    [string]$Version
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if (-not $Version) {
    $Version = git -C $RepoName name-rev --name-only --tags HEAD
    if ($Version -eq 'undefined') {
        $Version = git -C $RepoName describe --tags --abbrev=0
        $Version = git -C $RepoName tag --points-at $Version "--sort=-v:refname" | Select-Object -First 1 # ensure we're using the biggest of possible multiple tags
    } else {
        Write-Host "HEAD is already tagged: $Version"
        return $Version # return existing tag if tagged
    }
}

# Bump patch version component
if ($Version -cmatch '(.*)\.(\d+)$') {
    $newVersion = "$($Matches.1).$([int]$Matches.2 + 1)"
    Write-Host "Bumping $Version to $newVersion"
    return $newVersion
}

Write-Error "Failed to parse version: $Version"
