# Environments

## Introduction

These scripts are designed to be run in GitHub workflows. Though some scripts may be runnable locally.
The idea is to contain common setups which will be required by multiple repositories. For example, a build tool that
is needed for a certain language, but is not present byu default.

## MSBuild

**Script: `setup-msbuild.ps1`**

This is limited to Windows images.

It installs VSWhere, and runs it to find the location of the MSBuild executable. Once found, it is added to the path.
Specifically, it uses `GITHUB_PATH` so that the tool is available in subsequent jobs.
