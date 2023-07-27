param(
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [Hashtable]$Keys
)

try {
    $Tag = "$($Keys.DockerRegistry)/$($Keys.DockerContainer):$Version"
    $LatestTag = "$($Keys.DockerRegistry)/$($Keys.DockerContainer):latest"

    Write-Output "Logging in to docker hub"
    docker login -u $Keys.DockerUser -p $Keys.DockerPassword
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Setting docker image $Tag as latest"
    docker tag $Tag $LatestTag
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Pushing docker image $LatestTag"
    docker push $LatestTag
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Write-Output "Logging out of docker hub"
    docker logout
}

exit $LASTEXITCODE
