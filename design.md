# Design

This document lays out the overall design of continuous integration in this repository.

## Structure

### Workflows

Workflows are the overall scripts which achieve a goal of CI. For example, one workflow will
run all the tests required to merge a pull request, then complete the pull request.
Workflows mainly focus on the order of steps, and the actual work is done by individual steps.
Workflows are implemented in both PowerShell, and GitHub Actions.
A table of workflows can be found in [Readme](./README.md).

### Steps

Steps are the scripts called by workflows. Almost exclusively implemented in PowerShell. The only
exception is setting up an environment, which is a set up step when running in GitHub Actions.
Details of the steps can be found in [Readme](./README.md)

### Passing Variables

Input variables are passed to scripts in the standard way for PowerShell scripts.

Output variables are handled in one of two ways. Where possible, exit codes are used. Zero for
success, and non-zero otherwise. This should always be checked by the calling script, using
`$LASTEXITCODE`. Where more complex values are required, a variable name is passed as an input
parameter, and the parameter is set within the script using the `Set-Variable` function, using
`-Scope 1` so it is available to the caller (and only the caller).


### Inversion of Control

By using the principals of inversion of control, many of the scripts can be generic, thus avoiding
duplication. The non generic part which must be provided to a workflow is the name of the repository
it is running on. This repository then defines exactly what it wants to do, using the common steps
as much as possible. This design means that there can be a single workflow, which can be run of many
repositories, and does not need to be specific about the language in it's design.

An example of a fully generic step is cloning a repository, or creating a pull request.
An example of a step which relies on inversion of control is building or testing a project.

Generally, the order of execution is:
1. Workflow is called with a repo name,
2. Workflow calls a script within the repo (e.g. build) with any configuration required,
3. The script within the repo then calls a generic script with the configuration required.

For example, for the pipeline-dotnet repository, the build step would look something
like:
1. Workflow calls `pipeline-dotnet/ci/build-project.ps1` with the build configuration e.g. `x64` and `Debug`,
2. That script then calls `dotnet/build-project.ps1` with the build configuration,
3. If the build succeeds, an exit code of 0 is returned, and this repeats all the way up.

### Entering Directories

Most steps are run from within a repository that has been cloned by the workflow. To ensure that
the correct working directory is always maintained, the following pattern is used:

```powershell
Push-Location $RepoPath

try {

    # Here is where we carry out the logic in the repository
    # directory.

}
finally {

    Pop-Location

}

exit $LASTEXITCODE
```

## Logging

Logging should be carried out using `Write-Output`, unless it is a warning or an error, in which case `Write-Warning` and `Write-Error` are used respectively.

## Testing

## Integration Tests

The principal of integration tests is to test the package as a user would. I.e. the tests should not be run
from within a project, but instead be separate, and depend to the package built from the project.

To achieve this, the arrangement of integration tests is as follows:
1. Examples exist in a separate repository to the project they are demonstrating,
2. Examples reference packages using the relevant package manager e.g. NuGet, NPM, etc.,
3. Integration tests build the package, and deploy somewhere local (or a staging endpoint),
4. Integrations tests then clone the examples, update the references, and point to the staging source,
5. Examples are run as tests to confirm that the package works as intended.

