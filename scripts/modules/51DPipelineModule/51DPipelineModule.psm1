<#
  ===================== Pipeline =====================
  .Description
  This module contains functions that perform actions
  on Azure Devops pipelines.
  For more information, please read description of
  each function.
#>

# Obtain the list of pipelines to access pipeline id later.
$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/pipelines?api-version=6.0-preview.1"

$response = Invoke-WebRequest `
-URI $url `
-Headers @{
	Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
} `
-Method GET

if (!$(Test-RestResponse `
	-Response $response `
	-ErrorMessage "Failed to get the list of pipelines.")){
	# Exit with Error
	Exit 1
}

# This variables is read-only
$pipelines = $response.content | Out-String | ConvertFrom-Json

<#
  .Description
  Get the Id number of a pipeline.
  
  .Inputs Name
  Name of the pipeline.
  
  .Outputs
  Id number of the pipeline or $null if nothing found.
#>
function Get-PipelineId {
	param (
		[string]$Name
	)
	
	for ($i = 0; $i -lt $pipelines.count; $i++) {
		if ($pipelines.value[$i].name -eq $Name) {
			Write-Host "# ID $($pipelines.value[$i].id) found for pipeline $Name."
			return $pipelines.value[$i].id
		}
	}
	Write-Host "# No ID found for pipeline $Name."
	return $null
}
