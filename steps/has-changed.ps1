
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$ResultName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

Write-Output "Checking Changes"
$changes = $(git diff --name-only)

Write-Output "There are '$($changes.count)' changes:"
foreach ($change in $changes) {
    Write-Output "`t$change"
}

Write-Output "Leaving '$RepoPath'"
Pop-Location

Write-Output "Setting '`$$ResultName'"
Set-Variable -Name $ResultName -Value $changes.count > 0 -Scope 1