
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

. ./constants.ps1

./steps/clone-repo.ps1 -RepoName $RepoName

./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "get-next-package-version.ps1" -Options @{VariableName = "Version"}

./steps/package-update-required.ps1 -RepoName $RepoName -Version $Version

if ($LASTEXITCODE -eq 0) {

    ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "fetch-assets.ps1"

    # TODO for now we are assuming the file exists. This needs to be defined in docs.
    $OptionsFile = [IO.Path]::Combine($pwd, $RepoName, "ci", "options.json")

    foreach ($Options in $(Get-Content $OptionsFile | ConvertFrom-Json)) {

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "build-package.ps1"

        if ($LASTEXITCODE -eq 0) {

            ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "run-integration-tests.ps1" -Options $Options

        }

        ./steps/run-repo-script.ps1 -RepoName $RepoName -ScriptName "publish-package.ps1" -Options @{Version = $Version}

        ./steps/update-tag.ps1 -RepoName $RepoName -Tag $Version

    }

    if ($LASTEXITCODE -ne 0) {

        exit 1

    }
}