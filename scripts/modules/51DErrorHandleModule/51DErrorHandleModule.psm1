<#
  ===================== Error Handling =====================
  .Description
  This module contains functions that perform error handling
  actions.
  For more information, please read description of
  each function.
#>

<#
  .Description
  Check a Rest Response and return
  whether it is successful or not.

  .Parameter Response
  
  .Outputs true or false
#>
function Test-RestResponse {
	param (
		$Response,
		[string]$ErrorMessage
	)

	if ($Response.StatusCode -le 599 -and $Response.StatusCode -ge 400) {
		Write-Host "# ERROR: Status Code returned $($Response.StatusCode)"
		Write-Host "# ERROR: $ErrorMessage"
		# return $false
		throw "# ERROR: Rest api call failed."
	}
	return $true
}