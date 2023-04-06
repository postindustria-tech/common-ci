
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$LicenseKey
)

$CommonPath = $pwd
$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $FileName = [IO.Path]::Combine($pwd, "TAC-HashV41.hash.gz")
    
    Write-Output "Downloading Hash data file"
    $Result = $(& $CommonPath\steps\download-data-file.ps1 -licenseKey $LicenseKey -dataType "HashV41" -product "V4TAC" -fullFilePath $FileName)

    if ($Result -eq $False) {

        Write-Error "Failed to download data file"
        exit 1

    }

    Write-Output "Extracting $FileName"
    & $CommonPath\steps\unzip-file.ps1 -Source $FileName
    
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}