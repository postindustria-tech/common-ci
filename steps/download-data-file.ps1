param (
    [Parameter(Mandatory=$true)]
    [string]$LicenseKey,
    [Parameter(Mandatory=$true)]
    [string]$DataType,
    [Parameter(Mandatory=$true)]
    [string]$Product,
    [Parameter(Mandatory=$true)]
    [string]$FullFilePath,
    [string]$Url = $Null
)

$Uri ??= "https://distributor.51degrees.com/api/v2/download?LicenseKeys=$LicenseKey&Type=$DataType&Download=True&Product=$Product"
Invoke-WebRequest -Uri $Uri -OutFile $FullFilePath -MaximumRetryCount 10 -RetryIntervalSec 1 -ConnectionTimeoutSeconds 60 -OperationTimeoutSeconds 240
