param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

Push-Location $RepoName

npm install (Get-ChildItem -Path ../package -Filter *.tgz) || $(throw "npm install failed")

$items = Get-ChildItem -Path . -Force

foreach ($item in $items) {
    if ($item.Attributes -band [System.IO.FileAttributes]::Directory) {
        Write-Host "Directory: $($item.Name)"
    } else {
        Write-Host "File: $($item.Name)"
    }
}

Pop-Location

