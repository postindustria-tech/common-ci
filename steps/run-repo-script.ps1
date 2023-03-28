param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$ScriptName,
    [string]$ResultName,
    $Options
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$BuildScript = [IO.Path]::Combine($RepoPath, "ci", $ScriptName)

Write-Output "Running script '$BuildScript'"
# TODO Check if the script options param and exists
. $BuildScript -Options $Options

exit $LASTEXITCODE
