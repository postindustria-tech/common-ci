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

$OrgUsers = hub api /orgs/51degrees/members | ConvertFrom-JSON

function IsOrgUser {
    param (
        [string]$UserId
    )
    foreach ($OrgUser in $OrgUsers) {
        if ($OrgUser.id -eq $UserId) {
            return $True
        }
    }
    return $False
}

function HasReviewed {
    param (
        [string]$UserId,
        $Reviews
    )
    foreach ($Review in $Reviews) {
        if ($Review.user.id -eq $UserId -and
            $Review.state -eq 'APPROVED') {
                return $True
        }
    }
    return $False
}

function ShouldRun {
    param (
        [string]$RepoName,
        [string]$Id
    )
    $Allowed = $True
    $Reviews = hub api /repos/51degrees/$RepoName/pulls/$Id/reviews | ConvertFrom-JSON
    $Pr = hub api /repos/51degrees/$RepoName/pulls/$Id | ConvertFrom-Json
    if ($Pr.author_association -eq 'OWNER' -or
        $Pr.author_association -eq 'COLLABORATOR' -or
        $Pr.author_association -eq 'CONTRIBUTOR' -or
        $Pr.author_association -eq 'MEMBER') {
        # The author is one of the above, so return true
        Write-Information "The creator is '$($Pr.author_association)', so allow automation"
        $Allowed = $True
    }
    else {
        # The author is not one of the above, so check that
        # the PR has been approved
        foreach ($Review in $Reviews) {
            if ($Review.state -eq 'APPROVED') {
                if (IsOrgUser -UserId $Review.user.id) {
                    Write-Information "The creator is external, but has been approved by '$($Review.user.id)', so allow automation"
                    $Allowed = $True
                }
            }
        }
    }
    if ($Pr.requested_reviewers.Count -gt 0) {
        foreach ($Reviewer in $Pr.requested_reviewers) {
            $User = hub api /users/$($Reviewer.login) | ConvertFrom-Json
            if ($(HasReviewed -UserId $User.id -Reviews $Reviews) -eq $False) {
                Write-Information "The user '$($User.login)' has not approved, so do not run automation"
                $Allowed = $False
            }
        }
    }
    return $Allowed
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
            # Only select PRs which are eligeble for automation.
            Write-Output "Checking PR #$Id"
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

