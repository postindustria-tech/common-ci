
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [string]$RunId,
    [string]$PullRequestId,
    [string]$ResultsPath = ""
)

# Disable progress bars
$ProgressPreference = "SilentlyContinue"

function Get-Artifact-Result {
    param (
        [Parameter(Mandatory=$true)]
        $Artifact,
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    Invoke-WebRequest -Uri $Artifact.archive_download_url -Headers @{"Authorization" = "Bearer $($env:GITHUB_TOKEN)"} -Outfile "$($Artifact.id).zip"
    Expand-Archive -Path "$($Artifact.id).zip" -DestinationPath $Artifact.id -Force
    $TargetFile = [IO.Path]::Combine($Artifact.id, "results_$Name.json")
    if (Test-Path -Path $TargetFile) {
        $Result = Get-Content $TargetFile | ConvertFrom-Json -AsHashtable
        $Result.Artifact = $Artifact
    }
    else {
        $Result = $Null
    }
    return $Result
}

function Generate-Performance-Results {
    param(
        $Results,
        $CurrentResult,
        $Artifacts,
        $CurrentArtifact,
        [string]$Metric,
        [bool]$HigherIsBetter
    )

    # Calculate the mean and standard deviation
    $Sum = 0
    $Results | ForEach-Object { $Sum += $_}
    if ($Results.Length -gt 0) {
        $Mean = $Sum / $Results.Length
        $SumOfSquares = 0
        foreach ($Result in $Results) {
            $Diff = $Result - $Mean
            if ($Diff -lt 0) {
                $Diff = 0 - $Diff
            }
            $SumOfSquares += $($Diff * $Diff)
        }
        
        $Variance = $SumOfSquares / $Results.Length
        $Deviation = [Math]::Sqrt($Variance)
    }
    else {
        $Mean = 0
        $Variance = 0
        $Deviation = 0
    }

    Write-Output "Mean is '$Mean' with a standard deviation of '$Deviation'"
    Write-Output "Current result is '$CurrentResult'"

    Push-Location $RepoName

    try {

        # Check out the gh-images branch so we're ready to commit images.
        $branches = $(git branch -a --format "%(refname)")
        $CurrentBranch = $(git rev-parse --abbrev-ref HEAD)
        $ImagesBranch = "gh-images"
        if ($branches.Contains("refs/remotes/origin/$ImagesBranch")) {
            Write-Output "Checking out branch '$ImagesBranch'"
            git checkout $ImagesBranch
        }
        else {
            Write-Output "Creating new branch '$ImagesBranch'"
            git checkout --orphan $ImagesBranch
            git rm -rf .
        }

        # Construct all the points on the graph
        $Xs = @()
        $Ys = @()
        foreach ($i in 0..$($Results.Length - 1)) {
            $Artifact = $Artifacts[$i]
            $Result = $Results[$i]
            $Xs += $Artifact.created_at.ToOADate()
            $Ys += $Result
        }
        $Xs += $CurrentArtifact.created_at.ToOADate()
        $Ys += $CurrentResult

        # Set up the graph
        $Plot = [ScottPlot.Plot]::new(400, 300)
        $Plot.AxisAuto(0.2, 0.5)
        #$Plot.AxisZoom(0.5, 1)
        $Plot.Legend($True, [ScottPlot.Alignment]::UpperLeft)
        $Plot.Title("Config : '$Name'", $Null, $Null, $Null, $Null)
        $Plot.XLabel("Date of Performance Test")
        $Plot.YLabel($Metric)
        $Plot.XAxis.DateTimeFormat($True)

        # Add the current performance figure
        $Plot.AddPoint($CurrentArtifact.created_at.ToOADate(), $CurrentResult, $Null, 15, [ScottPlot.MarkerShape]::openCircle, "current")
        # Add the historic figures
        $Plot.AddScatter($Xs, $Ys, $Null, 1, 5, [ScottPlot.MarkerShape]::filledCircle, [ScottPlot.LineStyle]::Solid, "historic")
        # Add the standard deviation
        $Plot.AddVerticalSpan($($Mean - $Deviation), $($Mean + $Deviation))

        # Output the graph
        $Plot.SaveFig("$pwd/perf-graph-$RunId-$PullRequestId-$Name-$Metric.png")

        # Commit the image, and change back to the original branch
        git add "$pwd/perf-graph-$RunId-$PullRequestId-$Name-$Metric.png"
        git commit -m "Added performance graph for for $RunId-$PullRequestId-$Name-$Metric"
        git push origin $ImagesBranch
        git checkout $CurrentBranch
    }
    finally {
        Pop-Location
    }

    # Write out the summary for GitHub actions
    if ($Null -ne $env:GITHUB_STEP_SUMMARY) {
        Write-Output "## Performance Figures - $Name - $Metric" >> $env:GITHUB_STEP_SUMMARY
        Write-Output "![Historic Performance Figures](https://raw.githubusercontent.com/51Degrees/$RepoName/gh-images/perf-graph-$RunId-$PullRequestId-$Name-$Metric.png)" >> $env:GITHUB_STEP_SUMMARY
        Write-Output "| Date | $Metric |" >> $env:GITHUB_STEP_SUMMARY
        Write-Output "| ---- | ---------------- |" >> $env:GITHUB_STEP_SUMMARY
        foreach ($i in 0..$($Results.Length - 1)) {
            $Artifact = $Artifacts[$i]
            $Result = $Results[$i]
            Write-Output "| $($Artifact.created_at) | $Result |" >> $env:GITHUB_STEP_SUMMARY
        }
    }

    # Check if the current result is more than 2 standard deviations out.
    $Passed = $False
    if ($HigerIsBetter) {
        $Passed = $CurrentResult -gt ($Mean - ($Deviation * 2))
    }
    else {
        $Passed = $CurrentResult -lt ($Mean + ($Deviation * 2))
    }
    if ($Passed -eq $False) {
        
        if ($Results.Length -lt 10) {
            Write-Warning "The performance of '$Metric' is more than 2 standard deviations from the mean for '$Name'. 
            There are only '$($Results.Length)' historic results, so this will not be considered a failure"
        }
        else {
            Write-Warning "The performance of '$Metric' is more than 2 standard deviations from the mean for '$Name'."
            exit 1
        }
    }
}

# Get all the artifactrs
$Artifacts = $(hub api /repos/51degrees/$RepoName/actions/artifacts | ConvertFrom-Json).artifacts

# Get the artifact for the current run
if ($ResultsPath -ne "") {
    if ($(Test-Path -Path $ResultsPath) -eq $False) {
        Write-Warning "The file '$ResultsPath' did not exist"
        exit 0
    }
    $CurrentResult = Get-Content $ResultsPath | ConvertFrom-Json -AsHashtable
    $CurrentResult.Artifact = @{}
    $CurrentResult.Artifact.created_at = Get-Date
}
else {
    $CurrentArtifact = $Artifacts | Where-Object { $_.workflow_run.id -eq $RunId -and $_.name -eq "performance_results_$PullRequestId" }
    $CurrentResult = Get-Artifact-Result -Artifact $CurrentArtifact -Name $Name
}

# Get the result for the current artifact

# Filter the artifacts so we only have ones that have passed the performance tests
$Artifacts = $Artifacts | Where-Object { $_.name.StartsWith("performance_results_passed") }

# Sort by date
$Artifacts = $Artifacts | Sort-Object -Property created_at


# Get the performance results from the artifacts
$Results = @()
foreach ($Artifact in $Artifacts) {
    $Result = Get-Artifact-Result -Artifact $Artifact -Name $Name
    if ($Null -ne $Result) {
        $Results += $Result
    }
}
$Results += $CurrentResult

if ($CurrentResult -eq 0) {
    Write-Error "Results for the workflow run '$RunId' were not found"
    exit 1
}

# Install ScottPlot
$PlotReady = $False
try {
    $Plot = [ScottPlot.Plot]::new(400, 300)
    $PlotReady = $True
} catch {}
if ($PlotReady -eq $False) {
    $PlotPath = [IO.Path]::Combine($pwd, "plot")        
    if ($(Test-Path -Path $PlotPath)) {
        Remove-Item -Recurse -Force -Path $PlotPath
    }
    mkdir $PlotPath
    Push-Location $PlotPath
    try {
        dotnet new console
        dotnet add package scottplot
        dotnet build -o bin
    }
    finally {
        Pop-Location
    }
    Add-Type -Path $([IO.Path]::Combine($PlotPath, "bin", "ScottPlot.dll"))
}
# Generate the performance results for all metrics
foreach ($Metric in $CurrentResult.HigherIsBetter.Keys) {
    $MetricResults = @()
    $MetricArtifacts = @()
    foreach ($Result in $Results) {
        if ($Null -ne $Result.HigherIsBetter -and $Null -ne $Result.HigherIsBetter[$Metric]) {
            $MetricResults += $Result.HigherIsBetter[$Metric]
            $MetricArtifacts += $Result.Artifact
        }
    }
    Generate-Performance-Results -Results $MetricResults -CurrentResult $CurrentResult.HigherIsBetter[$Metric] -Artifacts $MetricArtifacts -CurrentArtifact $CurrentResult.Artifact -Metric $Metric -HigherIsBetter $True
}
foreach ($Metric in $CurrentResult.LowerIsBetter.Keys) {
    $MetricResults = @()
    $MetricArtifacts = @()
    foreach ($Result in $Results) {
        if ($Null -ne $Result.LowerIsBetter -and $Null -ne $Result.LowerIsBetter[$Metric]) {
            $MetricResults += $Result.LowerIsBetter[$Metric]
            $MetricArtifacts += $Result.Artifact
        }
    }
    Generate-Performance-Results -Results $MetricResults -CurrentResult $CurrentResult.LowerIsBetter[$Metric] -Artifacts $MetricArtifacts -CurrentArtifact $CurrentResult.Artifact -Metric $Metric -HigherIsBetter $False
}
