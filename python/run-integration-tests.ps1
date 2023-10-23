param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string[]]$Packages,
    [Parameter(Mandatory=$true)]
    [hashtable]$Keys
)

$env:resource_key = $Keys.TestResourceKey
$env:license_key = $Keys.DeviceDetection

$commonTestResults = New-Item -ItemType directory -Path $RepoName/test-results/integration -Force
$repoPath = Get-Item -Path $RepoName
$testsFailed = $false

Push-Location $RepoName
try {
    foreach ($package in $Packages) {
        Write-Output "Testing $package"
        Push-Location $package
        try {
            Write-Output "Running tests in '$pwd'"
            # coverage run -m xmlrunner discover -s tests -p 'test*.py' -o $commonTestResults || $($testsFailed = $true)
            $packageName = Split-Path -Path $pwd -Leaf # Required for location-python, which uses . as package path
            $coverageOutputFile = Join-Path -Path $commonTestResults -ChildPath "$packageName.xml"
            python -m tox -e py -- --junit-xml=$coverageOutputFile || $($testsFailed = $true)
            Move-Item -Path .coverage -Destination $repoPath/.coverage.$packageName || $(throw "failed to move coverage report")
        } finally {
            Pop-Location
        }
    }
    coverage combine || $(throw "coverage combine failed")
    coverage xml || $(throw "coverage xml failed")
} finally {
    Pop-Location
}

exit $testsFailed ? 1 : 0
