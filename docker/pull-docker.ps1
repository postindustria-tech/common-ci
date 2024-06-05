param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [Hashtable]$Keys,
    [Parameter(Mandatory=$true)]
    [string]$DockerRegistry,
    [Parameter(Mandatory=$true)]
    [string]$DockerContainer
)

try {
    $Tag = "$($DockerRegistry)/$($DockerContainer):$Version"

    Write-Output "Logging in to docker hub"
    docker login -u $Keys.DockerUser -p $Keys.DockerPassword
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Output "Pulling docker image $Tag"
    docker pull $Tag
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Write-Output "Logging out of docker hub"
    docker logout
}
