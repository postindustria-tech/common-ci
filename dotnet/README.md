# .NET SPECIFIC CI/CD Approach

The CI/CD pipeline in this project adheres to the principles outlined in the common-ci project, with the following exceptions:

## Environment

The script `setup-environment.ps1` is specific for each repository and is responsible for configuring essential environment variables required for running tests. These variables include the location of data files and the resource key. On Linux systems, it may also handle the installation of multilib if needed. Additionally, in cases where the project is utilizing the msbuild command instead of dotnet, the script ensures that both msbuild and vstest are appropriately added to the PATH variable. 


## Build

Dotnet projects  include two distinct build scripts: one for the core and another for the framework. In cases where projects contain multiple solutions per project, it is necessary to pass the solution name as a parameter to the "ProjectDir."

## Tests

Due to the presence of both core and framework projects in our repositories, both dotnet and msbuild commands may be employed to test different configurations. The BuildMethod parameter, specified in options.json, determines these commands. Instead of testing the solution file, the tests are performed on the assembly, enabling us to exclude framework projects that are not built. This approach helps us avoid the challenge of inconsistent behavior across different dotnet commands and addresses the problem of varying expectations for the bin folder location based on different configurations during the build process.

## Packaging 

The packages are signed in the `build-packages-nuget.ps1` script as they are built in the folder from which they will be ultimately published. The content of the `.pfx` file is defined in the secrets and is passed to the script and written to a file inside the script which is then passed to the pack command.

## Updating Dependencies 

The `run-update-dependencies.ps1` script loops through each .csproj file found in the repository to identify outdated packages for each project. By iterating through the projects and packages, the script can analyze and update each project individually, ensuring that the package updates are performed at the appropriate project level.

The script executes the dotnet list command to retrieve a list of outdated packages for the project. It then filters the output to consider only lines starting with >, indicating outdated packages. From each line, it extracts the package name, major version, minor version, and patch version using regular expressions.

Next, it searches for the available versions of the package on the NuGet package source https://api.nuget.org/v3/index.json, matching the major and minor versions. The available versions are sorted in ascending order based on the patch version, and the last (highest) version is selected.

The script checks if the highest patch version differs from the currently installed version. If an update is required it executes dotnet add command to update the package to the highest available version.