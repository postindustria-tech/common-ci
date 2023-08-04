param(
    [string]$ImageFile = "dockerimage.tag.gz"
)

$PackagePath = [IO.Path]::Combine($pwd, "package")
$PackageFile = [IO.Path]::Combine($PackagePath, $ImageFile)

Write-Output "Loading image from '$PackageFile'"
docker load --input $PackageFile

exit $LASTEXITCODE
