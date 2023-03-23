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
# TODO Check if the script accepts results/options param and exists
. $BuildScript -ResultName $ResultName -Options $Options

Write-Output "Setting '`$$ResultName'"
$InnerResult = Get-Variable -Name $ResultName
Set-Variable -Name $ResultName -Value $InnerResult -Scope 1
