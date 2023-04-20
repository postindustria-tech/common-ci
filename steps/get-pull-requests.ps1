param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $Ids = $(hub pr list -f "%I," -b main)
    if ($Null -ne $Ids) {
        $Ids = $Ids.Trim(",")

        $ValidIds = @()

        foreach ($Id in $Ids) {

            # Only select PRs which are eligeble for automation.
            $Pr = hub api /repos/51degrees/$RepoName/pulls/$Id | ConvertFrom-Json
            if ($Pr.author_association -eq 'OWNER' -or
                $Pr.author_association -eq 'COLLABORATOR' -or
                $Pr.author_association -eq 'CONTRIBUTOR' -or
                $Pr.author_association -eq 'MEMBER')
            {
                $ValidIds += $Id
            }

        }

        Write-Output "Pull request ids are: $ValidIds"
        Write-Output pull_request_ids="[$ValidIds]" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append

    } else {

        Write-Output "No pull requests to be checked."
        Write-Output pull_request_ids="[0]" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append

    }
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

