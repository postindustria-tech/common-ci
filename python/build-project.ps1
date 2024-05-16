param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string[]]$Packages,
    [string[]]$WithExtensions
)

foreach ($package in $Packages) {
    Push-Location $RepoName/$package
    try {
        if ($package -in $WithExtensions) {
            Write-Output "Building extensions of $package"
            python setup.py build_clib build_ext --inplace
        }

        Write-Output "Building $package"
        pip install . || $(throw "failed to build $package")

        # Special case - if package is a '.' we can't just lint the subdir with
        # the same name, so instead we'll lint the first subdir with the name
        # that starts with 'fiftyone*'
        if ($package -eq '.') {
            $package = (get-item src/fiftyone_*)[0].Name
        }

        Write-Output "Linting $package"
        pylint --version
        pylint --rcfile=.pylintrc (Join-Path -Path (Get-Item src) -ChildPath $package) || $(throw "pylint failed for $package")
    } finally {
        Pop-Location
    }
}
