param (
    [Parameter(Mandatory)][string]$RepoName,
    [string]$Config = "$PSScriptRoot/../GitVersion.yml",
    [string]$Format = '{SemVer}'
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

dotnet-gitversion $RepoName /config $Config /format $Format
