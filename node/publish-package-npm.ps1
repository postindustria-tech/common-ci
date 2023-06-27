param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [boolean]$DryRun

)

Push-Location $RepoName

try {
    # Using NPM Token to sign in
    npm config set //registry.npmjs.org/:_authToken $Options.Keys.NPMAuthToken

    if (!$DryRun) {
        # Publishing with new version
        # Disabled during missing auth_token
        $packages = Get-ChildItem -Path ./../package -Filter *.tgz
        foreach($package in $packages ){
            npm publish $package --access public --tag latest || $(throw "ERROR: Package upload failed")
        }
    } else {
        Write-Output "Dry run: skipping package upload"
    }
} finally {
    Pop-Location
}

exit $LASTEXITCODE

