param (
    [string]$RepoName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$DocsPath = [IO.Path]::Combine($RepoPath, "docs")
$DoxyGenPath = [IO.Path]::Combine($pwd, "tools", "DoxyGen")
$DoxyGen = [IO.Path]::Combine($DoxyGenPath, "doxygen")

Write-Output "Setting up requirements"
sudo apt-get install -y graphviz flex bison

Write-Output "Entering '$DoxyGenPath'"
Push-Location $DoxyGenPath
try {

    Write-Output "Extracting DoxyGen executable"
    unzip -o doxygen-linux.zip
    Move-Item doxygen-linux $DoxyGen -Force

}
finally {
    Write-Output "Leaving '$DoxyGenPath'"
    Pop-Location
}

Write-Output "Marking '$DoxyGen' as executable"
chmod +x $DoxyGen

Write-Output "Entering '$DocsPath'"
Push-Location $DocsPath
try {

    Write-Output "Running DoxyGen"
    & $DoxyGen

}
finally {

    Write-Output "Leaving '$DocsPath'"
    Pop-Location

}

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath
try {
    $VersionPath = Get-ChildItem -Path $pwd -Filter "4.*"
    Move-Item $VersionPath.FullName "$($VersionPath.FullName)-new"

    # Check out the gh-pages branch so we're ready to commit images.
    $branches = $(git branch -a --format "%(refname)")
    $PagesBranch = "gh-pages"
    if ($branches.Contains("refs/remotes/origin/$PagesBranch")) {
        Write-Output "Checking out branch '$PagesBranch'"
        git checkout $PagesBranch -f --recurse-submodules
    }
    else {
        Write-Output "Creating new branch '$PagesBranch'"
        git checkout --orphan $PagesBranch
        git rm -rf .
    }

    if ($(Test-Path -Path $VersionPath.FullName)) {
        Remove-Item -Recurse -Path $VersionPath.FullName
    }
    if ($(Test-Path -Path ".nojekyll") -eq $False) {
        Write-Output "Creating a .nojekyll file"
        Write-Output "" > .nojekyll
    }

    Move-Item "$($VersionPath.FullName)-new" $VersionPath.FullName
}
finally {
    Write-Output "Leaving '$RepoPath'"
    Pop-Location
}
