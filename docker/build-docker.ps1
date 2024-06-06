param(
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [Hashtable]$Keys,
    [string]$ImageFile = "dockerimage.tar",
    [string]$Path = "."
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$PackagePath = [IO.Path]::Combine($pwd, "package")
$PackageFile = [IO.Path]::Combine($PackagePath, $ImageFile)
if ($(Test-Path -Path $PackagePath) -eq $false) {
    mkdir $PackagePath
}
Write-Output "$Version" > $PackageVersionPath

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath
try {
    $Tag = "$($Keys.DockerRegistry)/$($Keys.DockerContainer):$Version"

    Write-Output "Building docker image $Tag"
    docker build --tag $Tag $Path
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Saving docker image $Tag"
    docker save -o $PackageFile $Tag
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Write-Output "Leaving '$RepoPath'"
    Pop-Location
}

exit $LASTEXITCODE
