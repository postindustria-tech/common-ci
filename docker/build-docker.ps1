param(
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [Hashtable]$Keys
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath
try {
    $Tag = "$($Keys.DockerRegistry)/$($Keys.DockerContainer):$Version"

    Write-Output "Logging in to docker hub"
    docker login -u $Keys.DockerUser -p $Keys.DockerPassword
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Building docker image $Tag"
    docker build --tag $Tag .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Pushing docker image $Tag"
    docker push $Tag
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Write-Output "Leaving '$RepoPath'"
    Pop-Location
    Write-Output "Logging out of docker hub"
    docker logout
}

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output "Writing version to file"
$PackagePath = [IO.Path]::Combine($pwd, "package")
$PackageVersionPath = [IO.Path]::Combine($PackagePath, "version.txt")
if ($(Test-Path -Path $PackagePath) -eq $false) {
    mkdir $PackagePath
}
Write-Output "$Version" > $PackageVersionPath

exit $LASTEXITCODE
