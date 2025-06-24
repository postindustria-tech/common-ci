param (
    [Parameter(Mandatory)][string]$FullFilePath,
    [string]$Url,
    [string]$LicenseKey,
    [string]$DataType,
    [string]$Product
)
$ErrorActionPreference = "Stop"

if (!$Url -and (!$LicenseKey -or !$DataType -or !$Product)) {
    Write-Error "Either full Url or LicenseKey+DataType+Product must be provided"
}

$Url = $Url ? $Url : "https://distributor.51degrees.com/api/v2/download?LicenseKeys=$LicenseKey&Type=$DataType&Download=True&Product=$Product"
Invoke-WebRequest -Verbose -Uri $Url -OutFile $FullFilePath -MaximumRetryCount 3 -RetryIntervalSec 3 -ConnectionTimeoutSeconds 30 -OperationTimeoutSeconds 30
