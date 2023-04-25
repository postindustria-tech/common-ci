param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$VariableName = "PullRequestIds"
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

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
            $Pr = hub api /repos/51degrees/$RepoName/pulls/$Id | ConvertFrom-Json
            if ($Pr.author_association -eq 'OWNER' -or
                $Pr.author_association -eq 'COLLABORATOR' -or
                $Pr.author_association -eq 'CONTRIBUTOR' -or
                $Pr.author_association -eq 'MEMBER')
            {
                $ValidIds += $Id
            }

        }

        Write-Output "Pull request ids are: $([string]::Join(",", $ValidIds))"
        Set-Variable -Name $VariableName -Value $ValidIds -Scope Global

    } else {

        Write-Output "No pull requests to be checked."
        Set-Variable -Name $VariableName -Value @(0) -Scope Global

    }
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

