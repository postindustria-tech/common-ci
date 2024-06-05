param(
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [Hashtable]$Keys,
    [Parameter(Mandatory=$true)]
    [string]$DockerRegistry,
    [Parameter(Mandatory=$true)]
    [string]$DockerContainer,
    [string]$Dryrun
)

try {
    $Tag = "$($DockerRegistry)/$($DockerContainer):$Version"
    $LatestTag = "$($DockerRegistry)/$($DockerContainer):latest"

    Write-Output "Logging in to docker hub"
    docker login -u $Keys.DockerUser -p $Keys.DockerPassword
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Setting docker image $Tag as latest"
    docker tag $Tag $LatestTag
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    # Push to repository when dryrun is false
    $Command = {docker push $LatestTag}
    if ($DryRun -eq $False) {
        Write-Output "Pushing docker image $LatestTag"
        & $Command
    } else {
        Write-Output "Dry run - not executing the following: $Command"
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Write-Output "Logging out of docker hub"
    docker logout
}

exit $LASTEXITCODE
