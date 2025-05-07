param (
    [Parameter(Mandatory)][string]$RepoName,
    [Parameter(Mandatory)][string]$OrgName,
    [string]$Branch = "main",
    [string]$ForceSwitchTo,
    [string]$DestinationDir = "."
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

# Using short directory name to avoid/delay problems with long paths when cloning on Windows
$tmp = "$DestinationDir/b"

git clone --recurse-submodules --shallow-submodules --branch $Branch "https://github.com/$OrgName/$RepoName" $tmp

if ($ForceSwitchTo) {
    Write-Output "Switching to $ForceSwitchTo"
    git -C $tmp switch --recurse-submodules -C $ForceSwitchTo
}

git -C $tmp log -1

Write-Output "Renaming '$tmp' to '$RepoName'"
Rename-Item $tmp $RepoName
