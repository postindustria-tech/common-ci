param (
    $GitHubToken
)
git config --global url.https://$GitHubToken@github.com/.insteadOf https://github.com/
git config --global user.email "CI@51Degrees.com"
git config --global user.name "51DCI"
git config --global filter.lfs.smudge "git-lfs smudge --skip -- %f"
git config --global filter.lfs.process "git-lfs filter-process --skip"
git config --global core.longpaths true