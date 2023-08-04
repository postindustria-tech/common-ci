param(
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [Hashtable]$Keys
)

try {
    $Tag = "$($Keys.DockerRegistry)/$($Keys.DockerContainer):$Version"

    Write-Output "Logging in to docker hub"
    docker login -u $Keys.DockerUser -p $Keys.DockerPassword
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Pushing docker image $Tag"
    docker push $Tag
}
finally {
    Write-Output "Logging out of docker hub"
    docker logout
}

exit $LASTEXITCODE
