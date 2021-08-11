# Continuous Integration Tips
## Writing Script
When writing script to perform a batch job, a common bug that happens often is not verifying if a step has successfully completed. There are many instances where an error code is not caught and is subsequently overwritten by the following steps, resulting in a false positive result. Therefore, when writing a script task, the following tips would help to minimize this risk:
1. Always verify that the result of the script is as expected. Such as checking error code or checking if a certain conditions have been met. This can be done at a number of places in the script where a certain change could impact the final outcome.
2. Where a required condition was not met, log a message and exit with an appropriate non zero code. This will make sure the exit code will always be caught by the script task.

## Using variables from other jobs

When a variable in a separate job, in a separate template is required you may need to output it manually depending on the task that sets the variable.

For example the GitVersion task does not output variables it produces to the pipeline, you must create a separate script task to echo the variable like so:

```yml
- job: Tagging
  steps:

  # GitVersion task here.

  # Output the GitVersion.SemVer variable so it can be used in other jobs.
  - script: echo "##vso[task.setvariable variable=GitVersionSemVer;isOutput=true]$(GitVersion.SemVer)"
    name: setvarStep
```

Then you can access the variable in a separate job like:

```yml
- job: Build
  dependsOn: Tagging
  variables:
    # map the output variable from A into this job
    varFromTagJob: $[ dependencies.Tagging.outputs['setvarStep.GitVersionSemVer'] ]
  steps:
  - script: echo $(varFromTagJob) # this step uses the mapped-in variable
```