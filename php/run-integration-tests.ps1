param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

# Different tests require different environment variables, so they should be
# set by the caller, e.g.:
#   $env:RESOURCEKEY = $Keys.TestResourceKey

Push-Location $RepoName
try {
    phpunit --fail-on-warning --testsuite Integration --log-junit test-results/integration/$RepoName/tests.xml || $(throw "tests failed")
} finally {
    Pop-Location
}
