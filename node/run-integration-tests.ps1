param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName

$testsFailed = $false

try
{
    $env:RESOURCE_KEY = $Options.Keys.TestResourceKey

    Write-Output "Running integration tests"
    $env:JEST_JUNIT_OUTPUT_DIR = 'test-results/integration'
    npm run integration-test || $($testsFailed = $true)
} finally {
    Pop-Location
}

exit $testsFailed ? 1 : 0