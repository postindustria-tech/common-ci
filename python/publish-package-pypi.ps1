param (
    [Parameter(Mandatory=$true)]
    [hashtable]$Keys,
    [bool]$DryRun = $False
)

$env:TWINE_USERNAME = "__token__"

pip install twine || $(throw "pip install failed")
if (!$DryRun) {
    $env:TWINE_PASSWORD = $Keys.PypiToken
    twine upload (Get-ChildItem -Path package) || $(throw "package upload failed")
} else {
    # $env:TWINE_PASSWORD = $Keys.TestPypiToken
    # twine upload --repository testpypi (Get-ChildItem -Path package) || $(throw "package upload failed")
    Write-Output "Dry run: skipping package upload"
}
