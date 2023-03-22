param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$ScriptName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $BuildScript = [IO.Path]::Combine($RepoPath, "ci", $ScriptName)

    . $BuildScript
    
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}