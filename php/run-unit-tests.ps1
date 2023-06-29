param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName
try {
    phpunit --testsuite Unit --log-junit test-results/unit/$RepoName/tests.xml || $(throw "tests failed")
} finally {
    Pop-Location
}
