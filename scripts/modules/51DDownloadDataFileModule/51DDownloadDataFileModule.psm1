<#
  ==================== Download =====================
  .Description
  This module contains a function to download a data file
  from the 51Degrees Distributor.
#>

# Download a data file.
function Get-DataFile {

    param (
        [Parameter(Mandatory=$true)]
        [string]$licenseKey,

        [Parameter(Mandatory=$true)]
        [string]$dataType,

        [Parameter(Mandatory=$true)]
        [string]$product,

        [Parameter(Mandatory=$true)]
        [string]$fullFilePath
    )
    
    $webClient = New-Object System.Net.Http.HttpClient;
    $webClient.Timeout = New-TimeSpan -Seconds 240
    $url ="https://distributor.51degrees.com/api/v2/download?LicenseKeys=$($licenseKey)&Type=$($dataType)&Download=True&Product=$($product)"
    $start_time = Get-Date

    # Get download stream
    $stream = $webClient.GetStreamAsync($url)
    $stream.ConfigureAwait($false) > $null
    if ($null -ne $stream.Exception){ throw $stream.Exception }

    # Save stream to path
    try
    {
        $fileStream = [System.IO.File]::Create($fullFilePath)
        $stream.Result.CopyTo($fileStream)
    }
    finally
    {
        if ($null -ne $fileStream){ $fileStream.Dispose() }
        if (($null -ne $stream) -and ($stream.IsCompleted -eq $true)){ $stream.Dispose() }
    }

    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

Export-ModuleMember -Function Get-DataFile