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

    $timeoutWebclientCode = @"
using System.Net;

public class TimeoutWebClient : WebClient
{
    public int TimeoutSeconds;

    protected override WebRequest GetWebRequest(System.Uri address)
    {
        WebRequest request = base.GetWebRequest(address);
        if (request != null)
        {
        request.Timeout = TimeoutSeconds * 1000;
        }
        return request;
    }

    public TimeoutWebClient()
    {
        TimeoutSeconds = 100; // Timeout value by default
    }
}
"@;
    
    Add-Type -TypeDefinition $timeoutWebclientCode -Language CSharp
    $webClient = New-Object TimeoutWebClient;
    $webClient.TimeoutSeconds = 240;
    $url ="https://distributor.51degrees.com/api/v2/download?LicenseKeys=$($licenseKey)&Type=$($dataType)&Download=True&Product=$($product)"
    $start_time = Get-Date   
    $webClient.DownloadFile($url, $fullFilePath)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

Export-ModuleMember -Function Get-DataFile