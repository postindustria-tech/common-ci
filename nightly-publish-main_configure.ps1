
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    [Parameter(Mandatory=$true)]
    [string]$GitHubOutput
)

. ./constants.ps1

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName"
./steps/clone-repo.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Get Next Package Version"
./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "get-next-package-version.ps1" -Options @{VariableName = "Version"}
Write-Output version=$Version
$IsValid = [bool]([regex]::Match($Version, '^(\d+)\.(\d+)\.(\d+)(-SNAPSHOT)?$')) 
if ($IsValid -eq $False) {
  Write-Error "The package version was not valid: '$Version'"
  exit 1
}
Write-Output version=$Version | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Output "::group::Package Update Required"
try {
    ./steps/package-update-required.ps1 -RepoName $RepoName -Version $Version
  } finally {
    if ($LASTEXITCODE -eq 0) {
      Write-Output update_required=true | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
    } else {
      Write-Output update_required=false | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
    }
    # Exit with a zero exit code as we don't want to fail just because an update is not required.
    exit 0
  }
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Output "::group::Package Update Required"
$OptionsFile = [IO.Path]::Combine($pwd, $RepoName, "ci", "options.json")
$Options = Get-Content $OptionsFile | ConvertFrom-Json
$RequiredOptions = @()
foreach ($element in $Options)
{
  if ($element.PackageRequirement) {
    $element | Add-Member -Name "Version" -Value $Version -MemberType NoteProperty
    $RequiredOptions += $element
  }
}
if ($RequiredOptions.Count -eq 0) {
  # As there are no prebuild steps, add an empty one to ensure the YAML is still valid.
  $RequiredOptions += @{
    "Name" = "No Prebuild"
    "PackageRequirement" = $False
    "Image" = "ubuntu-latest"
  }
}
$RequiredOptions = $RequiredOptions | ConvertTo-Json -AsArray
$RequiredOptions = $RequiredOptions -replace "`r`n", "" -replace "`n", ""
Write-Host $RequiredOptions
Write-Output options=$RequiredOptions | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
