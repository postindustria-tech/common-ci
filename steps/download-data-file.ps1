
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


Add-Type -AssemblyName System.Net.Http

$webClient = New-Object System.Net.Http.HttpClient;
$webClient.Timeout = New-TimeSpan -Seconds 240

if ($Null -eq $Url) {
    if ($DataType -ne "HashV41" -and $DataType -ne "CSV") {
        Write-Error "'$DataType' is not a recognized data type."
        exit 1
    }
        
    $Url ="https://distributor.51degrees.com/api/v2/download?LicenseKeys=$($LicenseKey)&Type=$($DataType)&Download=True&Product=$($Product)"

}

$start_time = Get-Date
$complete = $false
$tryCount = 0

DO
{
    $tryCount++;
    Write-Host "Attempt: $tryCount"
    
    try
    {
        # Get download stream
        $stream = $webClient.GetStreamAsync($url)
        $stream.ConfigureAwait($false) > $null
        if ($null -ne $stream.Exception){ throw $stream.Exception }

        # Save stream to path
        try
        {
            $fileStream = [System.IO.File]::Create($FullFilePath)
            $stream.Result.CopyTo($fileStream)            
            $complete = $true
        }
        finally
        {
            if ($null -ne $fileStream){ $fileStream.Dispose() }
            if (($null -ne $stream) -and ($stream.IsCompleted -eq $true)){ $stream.Dispose() }
        }
    }
    catch
    {
        Write-Host "# ERROR downloading data file:"
        Write-Host $_.Exception
    }        
} While (($complete -eq $false) -and ($tryCount -le 10))

if($complete -eq $false)
{        
    throw "# ERROR: Data file download failed after $tryCount attempts."
}

Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"