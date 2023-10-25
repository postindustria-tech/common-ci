param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

$options = @("--fail-on-warning")

phpunit --atleast-version=10 | Out-Null
if ($LASTEXITCODE -eq 0) {
    $options += "--display-warnings"
}

Push-Location $RepoName
try {
    phpunit $options --testsuite Unit --log-junit test-results/unit/$RepoName/tests.xml || $(throw "tests failed")
} finally {
    Pop-Location
}
