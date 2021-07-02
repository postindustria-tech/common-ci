<#
  ===================== Build =====================
  .Description
  This module contains functions that perform actions
  on a or more Azure Devops build.
  For more information, please read description of
  each function.
#>

<#
  .Description
  Requeue a test build of a pull request.
  
  .Parameter ProjectName
  Name of the project
  
  .Parameter PullRequestId
  Id number of a pull request
  
  .Outputs true or false
#>
function Restart-TestBuild {
	param (
		[string]$ProjectName,
		[int32]$PullRequestId
	)
	
	# Get the merge branch of the pull request
	$ref = Get-MergeBranchName -PullRequestId $PullRequestId

	# Obtain test pipeline id of the project.
	$pipelineId = Get-PipelineId -Name "$ProjectName-test"
	
	# Get all runs for the pipeline.
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/build/builds?api-version=6.0"
	$jsonBody = @"
	{
		"definition" : {
			"id" : $pipelineId
		},
		"sourceBranch" : "$ref"
	}
"@

	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method POST `
	-ContentType "application/json" `
	-Body $jsonBody
	
	return $(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to rerun the test pipeline for pull request $PullRequestId.")
}

<#
  .Description
  Requeue a test build of a pull request.
  
  .Parameter BuildId
  Id number of a build.
  
  .Outputs Build object.
#>
function Get-Build {
	param (
		[int32]$BuildId
	)
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/build/builds/$($BuildId)?api-version=6.0"
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to get build object for build $BuildId.")) {
		$content = $response.content | Out-String | ConvertFrom-Json
		return $content
	} else {
		return $null
	}
}

<#
  .Description
  Cancel all other builds of a pipeline on a certain branch, except the specified build id.
  
  .Parameter PipelineName
  Name of a pipeline to check for the builds.
  
  .Parameter Branch
  Full reference name of a branch to check if the builds run on.
  
  .Parameter CurrentBuildId
  Build id.
  
  .Outputs true or false
#>
function Stop-PreviousBuilds {
	param (
		[string]$PipelineName,
		[string]$Branch,
		[string]$CurrentBuildId
	)
	
	Write-Host ""
	Write-Host "# Getting current builds."
	$pipelineId = Get-PipelineId -Name $PipelineName
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/build/builds?definitions=$pipelineId&branchName=$Branch&api-version=6.0"
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse -Response $response -ErrorMessage "Failed to get all current builds.")) {
		$content = $response.content | Out-String | ConvertFrom-Json
		$buildsToCancel = $content.value.Where({ ($_.status -eq 'inProgress') -and ($_.id -ne $CurrentBuildId) })
		$allCancelled = $true
		
		$currentBuild = Get-Build -BuildId $CurrentBuildId
		if ($currentBuild -eq $null) {
			Write-Host "# ERROR: Failed to obtain current build object."
			return $false
		}
		
		$currentBuildTime = Get-Date -Format yyyy-MM-ddTHH-mm-ss-ff $currentBuild.startTime
		foreach ($build in $buildsToCancel) {
			$buildTime = Get-Date -Format yyyy-MM-ddTHH-mm-ss-ff $build.startTime
			if ($buildTime -lt $currentBuildTime) {
				Write-Host ""
				Write-Host "# Cancelling build $($build.id)."
				$body = @"
				{
					"id" : $($build.id),
					"status" : "cancelling"
				}
"@	
		
				$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/build/builds/$($build.id)?api-version=6.0"
				$cancellingResponse = Invoke-WebRequest `
				-URI $url `
				-Headers @{
					Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
				} `
				-Method PATCH `
				-ContentType "application/json" `
				-Body $body
				
				if ($(Test-RestResponse -Response $cancellingResponse -ErrorMessage "Failed to cancle build $($build.id)")) {
					Write-Host "# SUCCESS"
				} else {
					Write-Host "# FAIL"
					$allCancelled = $false
				}
			}
		}
		return $allCancelled
	}
	return $false
}

Export-ModuleMember -Function Restart-TestBuild
Export-ModuleMember -Function Stop-PreviousBuilds