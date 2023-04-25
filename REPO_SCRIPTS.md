# Repository Scripts

These are scripts that must be present in the `ci` directory of each repository that uses the common workflows.

## Build Project

**Script: `build-project.ps1`**

Builds the project. This is passed any build configuration parameters required from the `options.json`, and should call language specific build scripts in `common-ci` where possble.

## Fetch Assets

**Script: `fetch-assets.ps1`**

Fetches any assets needed for building or testing. This should reuse common asset steps. It is passed a `keys` object as a parameter, which is a hashtable of any named keys passed as secrets to the the workflow.

## Get Next Package Version

**Script: `get-next-package-version.ps1`**

Gets the next version for the package. This must take a parameter of `ParameterName`, which it then must set to a string containing the next version for the package.

This should make use of the common version which returns the versions from GitVersion as an object.

## Install Package

**Script: `install-package.ps1`**

Install a prebuilt package locally from the `[repo]/package` directory.

As an example, if a NuGet package is downloaded to the `package` directory. This script would install it using NuGet.

## Package Dependency Update

**Script: `package-dependency-update.ps1`**

Updated any package dependencies to the latest patch version. This should reuse language specific scripts in `common-ci` where possible.

## Publish Package

**Script: `publish-package.ps1`**

Publish the local package (which was built with `build-package.ps1` and installed locally with `install-package.ps1`) to the appropriate package manager. This should use language specific scripts in `common-ci` where possible.

## Run Integration Tests

**Script: `run-integration-tests.ps1`**

Run any integration tests for the project. For implementation guidelines, see [Integration Tests](/DESIGN.md#integration-tests). This should use language specific scripts in `common-ci` where possible.

Results should be written to the `[repo]/test-results/integration` directory. Supported formats can be found on the [publish-unit-test-result](https://github.com/EnricoMi/publish-unit-test-result-action#generating-test-result-files) action readme.

## Run Performance Tests

**Script: `run-performance-tests.ps1`**

Run any performance tests for the project. For implementation guidelines, see [Integration Tests](/DESIGN.md#integration-tests). This should use language specific scripts in `common-ci` where possible.

Results should be written to the `[repo]/test-results/performance` directory. Supported formats can be found on the [publish-unit-test-result](https://github.com/EnricoMi/publish-unit-test-result-action#generating-test-result-files) action readme.

Performance figures are different from test results. These should be written to the `[repo]test-results/performance-summary/` directory in a specific format. See the [Performance Tests](/DESIGN.md#performance-tests) section for details.

## Run Unit Tests

**Script: `run-unit-tests.ps1`**

Run any unit tests for the project. This should use language specific scripts in `common-ci` where possible.

Results should be written to the `[repo]/test-results/unit` directory. Supported formats can be found on the [publish-unit-test-result](https://github.com/EnricoMi/publish-unit-test-result-action#generating-test-result-files) action readme.

## Setup Environment

**Script: `setup-environment.ps1`**

Setup any environment variables, or install any tools required for building and testing. This should use scripts from `common-ci/environments` where possible. See [Environments](/environments/README.md).

## Options

**Script: `options.json`**

This is an array of options which are passed to the scripts as parameters. For a more detailed description, see [Options](/DESIGN.md#build-options).