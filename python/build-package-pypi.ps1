param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [string[]]$Packages
)

$packagesDir = New-Item -ItemType directory -Path package -Force

Push-Location $RepoName
try {
    # Should probably be done in setup-environment.ps1, but it isn't called by
    # build-package.ps1, so doing it here for now
    pip install --upgrade pip
    pip install setuptools wheel build Cython || $(throw "pip install failed")

    foreach ($package in $Packages) {
        Write-Output "Packaging $package"
        Push-Location $package
        try {
            $Version | Out-File version.txt
            if ($package -eq "fiftyone_devicedetection_onpremise") {
                python setup.py sdist || $(throw "failed to build package $package")
            } else {
                python -m build || $(throw "failed to build package $package")
            }
            Move-Item -Path dist/* -Destination $packagesDir || $(throw "failed to move $package package")
        } finally {
            Pop-Location
        }
    }
} finally {
    Pop-Location
}
