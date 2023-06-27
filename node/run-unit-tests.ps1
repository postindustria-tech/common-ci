param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName

$testsFailed = $false

try
{
    Write-Output "Running unit tests"
    $env:JEST_JUNIT_OUTPUT_DIR = 'test-results/unit'
    npm run unit-test || $($testsFailed = $true)
} finally {
    Pop-Location
}

exit $testsFailed ? 1 : 0
