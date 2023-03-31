
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$LicenseKey
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Adding data file module"
$Env:PSModulePath += ";$([IO.Path]::Combine($pwd, 'scripts', 'modules'))"
Write-Output "Module Path: $($Env:PSModulePath)"

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $FileName = [IO.Path]::Combine($pwd, "TAC-HashV41.hash.gz")
    
    Write-Output "Downloading Hash data file"
    $Result = $(Get-DataFile -licenseKey $LicenseKey -dataType "HashV41" -product "V4TAC" -fullFilePath $FileName)

    if ($Result -eq $False) {

        Write-Error "Failed to download data file"
        exit 1

    }

    Write-Output "Extracting $FileName"
    Gunzip -Source $FileName
    
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}