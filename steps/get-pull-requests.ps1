param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$VariableName = "PullRequestIds",
    [string]$GitHubToken
)

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

function ShouldRun {
    param (
        [string]$RepoName,
        [string]$Id
    )
    $Pr = hub api /repos/51degrees/$RepoName/pulls/$Id | ConvertFrom-Json
    if ($Pr.author_association -eq 'OWNER' -or
        $Pr.author_association -eq 'COLLABORATOR' -or
        $Pr.author_association -eq 'CONTRIBUTOR' -or
        $Pr.author_association -eq 'MEMBER') {
        # The author is one of the above, so return true
        return $True
    }
    else {
        # The author is not one of the above, so check that
        # the PR has been approved
        $Reviews = hub api /repos/51degrees/$RepoName/pulls/$Id/reviews | ConvertFrom-JSON
        if ($Reviews.state -eq 'APPROVED') {
            $OrgUsers = hub api /orgs/51degrees/members | ConvertFrom-JSON
            foreach ($OrgUser in $OrgUsers) {
                if ($OrgUser.id -eq $Reviews.user.id) {
                    # The PR has been approved by a 51Degrees user,
                    # so return true
                    return $True
                }
            }
        }
    }
    # The user is external, and the PR has not been approved yet
    return $False
}

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    # The format here lists the ids of the PRs with commas
    $Ids = $(hub pr list -f "%I," -b main)
    if ($Null -ne $Ids) {
        # Because of the format we used above, we need to remove the trailing comma.
        # Then we convert to an array.
        $Ids = $Ids.Trim(",").Split(",")

        $ValidIds = @()

        foreach ($Id in $Ids) {
            Write-Output "checking"
            # Only select PRs which are eligeble for automation.
            if (ShouldRun -RepoName $RepoName -Id $Id)
            {
                $ValidIds += $Id
            }

        }

        if ($ValidIds.Count -gt 0) {
            Write-Output "Pull request ids are: $([string]::Join(",", $ValidIds))"
            Set-Variable -Name $VariableName -Value $ValidIds -Scope Global
        }
        else {
            Write-Output "No pull requests to be checked."
            Set-Variable -Name $VariableName -Value @(0) -Scope Global
        }

    } else {

        Write-Output "No pull requests to be checked."
        Set-Variable -Name $VariableName -Value @(0) -Scope Global

    }
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

