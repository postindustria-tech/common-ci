
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    [Parameter(Mandatory=$true)]
    [string]$GitHubOutput,
    [Parameter(Mandatory=$true)]
    [string]$PullRequestId
)

. ./constants.ps1

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName"
./steps/clone-repo.ps1 -RepoName $RepoName -Branch $BranchName
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Checkout PR"
./steps/checkout-pr.ps1 -RepoName $RepoName -PullRequestId $PullRequestId
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Get Build Options"
$OptionsFile = [IO.Path]::Combine($pwd, $RepoName, "ci", "options.json")
$Options = Get-Content $OptionsFile -Raw
$Options = $Options -replace "`r`n", "" -replace "`n", ""
Write-Output $Options
Write-Output options=$Options | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
$OptionsPerformance = @()
foreach ($Element in $($Options | ConvertFrom-Json)) {
  if ($Element.RunPerformance) {
    $OptionsPerformance += $Element
  }
}
 if ($OptionsPerformance.Count -eq 0) {
  # As there are performance tests, add an empty one to ensure the YAML is still valid.
  $OptionsPerformance += @{
    "Name" = "No Performance Tests"
    "RunPerformance" = $False
    "Image" = "ubuntu-latest"
  }
}
$OptionsPerformance = $OptionsPerformance | ConvertTo-Json -AsArray
$OptionsPerformance = $OptionsPerformance -replace "`r`n", "" -replace "`n", ""
Write-Output options-performance=$OptionsPerformance | Out-File -FilePath $GitHubOutput -Encoding utf8 -Append
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
