param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [string]$VariableName = "PullRequestIds",
    [string]$GitHubToken
)

# This token is used by the gh command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$Collaborators = gh api /repos/$OrgName/$RepoName/collaborators | ConvertFrom-Json

function Test-WriteAccess {
    param (
        [Parameter(Mandatory, Position=0)]
        [int]$UserId
    )
    $permissions = ($Collaborators | Where-Object id -EQ $UserId).permissions
    return $permissions.admin -or $permissions.maintain -or $permissions.push
}

function Test-Approval {
    param (
        [Parameter(Position=0)]
        [Object[]]$Reviews,
        [Object[]]$RequestedReviewers
    )

    # First, check if all required reviewers approved the PR; fail early if not
    foreach ($reviewer in $RequestedReviewers) {
        if ($Reviews | Where-Object { $_.user.id -eq $reviewer.id -and $_.state -ne 'APPROVED' }) {
            Write-Information "The pull request is not approved by the requested reviewer: $($reviewer.login)"
            return $False
        }
    }

    # Check if there's at least one approver with write access to the repo
    $approvals = ($Reviews | Where-Object { $_.state -eq 'APPROVED' -and (Test-WriteAccess $_.user.id) }).user.login
    if ($approvals) {
        Write-Information "The creator doesn't have write access, but the pull request has been approved by: $approvals"
        return $True
    }

    Write-Information "The creator doesn't have write access, and the pull request is not approved by anyone with write access to the repository"
    return $False
}

function Test-Pr {
    param (
        [Parameter(Mandatory, Position=0)]
        [string]$RepoName,
        [Parameter(Mandatory, Position=1)]
        [string]$Id
    )
    $InformationPreference = 'Continue'

    $Pr = gh api /repos/$OrgName/$RepoName/pulls/$Id | ConvertFrom-Json
    $Reviews = gh api /repos/$OrgName/$RepoName/pulls/$Id/reviews | ConvertFrom-JSON
    if (Test-WriteAccess $Pr.user.id) {
        Write-Information "The creator has write access"
        return $True
    } else {
        return Test-Approval $Reviews -RequestedReviewers $Pr.requested_reviewers
    }
}

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $Ids = gh pr list -B main --json number,isDraft --jq '.[]|select(.isDraft|not).number'
    if ($Null -ne $Ids) {
        $ValidIds = @()

        foreach ($Id in $Ids) {
            # Only select PRs which are eligeble for automation.
            Write-Output "Checking PR #$Id"
            if (Test-Pr $RepoName $Id) {
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

