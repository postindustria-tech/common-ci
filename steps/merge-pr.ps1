param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [int]$PullRequestId
)

. ./constants.ps1

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $PrTitle = $(hub pr show $PullRequestId -f "%i %H->%B : '%t'")

    $Pr = hub api /repos/51degrees/$RepoName/pulls/$PullRequestId | ConvertFrom-Json

    if ($Pr.author_association -eq 'OWNER' -or
        $Pr.author_association -eq 'COLLABORATOR' -or
        $Pr.author_association -eq 'CONTRIBUTOR' -or
        $Pr.author_association -eq 'MEMBER')
    {

        Write-Output "Merging PR $PrTitle"
        hub api /repos/51Degrees/$RepoName/pulls/$PullRequestId/merge -X PUT -f "commit_title=Merged Pull Request '$PrTitle'"
    
    }
    else {

        Write-Output "PR creator '$($Pr.user.login)' not permitted. Not merging PR $PrTitle"

    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
