param (
    [Parameter(Mandatory=$true)]
    $GitHubToken,
    [Parameter(Mandatory=$true)]
    $GitHubUser,
    [Parameter(Mandatory=$true)]
    $GitHubEmail
)
git config --global url.https://$GitHubToken@github.com/.insteadOf https://github.com/
git config --global user.email $GitHubEmail
git config --global user.name $GitHubUser
git config --global filter.lfs.smudge "git-lfs smudge --skip -- %f"
git config --global filter.lfs.process "git-lfs filter-process --skip"
git config --global core.longpaths true