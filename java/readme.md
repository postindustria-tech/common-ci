# Java Specific CI/CD Approach
This API complies with the `common-ci` approach.

## Code Signing
We use Maven to package our Java APIs. The process of signing the result packages for Maven is different from Dotnet signing process.
1. The signing process for Java uses `PGP ASCII Armored File` with file extension `.asc` instead of `.pfx` as in Dotnet.
2. The process requires the `.asc` file to be imported using `gpg`.
3. Then the result package will be signed as part of Maven `install` process using `maven-gpg-plugin`.

## Deploy External
The deployment to external of Java Maven packages must be done in the following order:

1. `pipeline-java`
2. `device-detection-java`
3. `location-java`

Steps for each java repo:
1. Deploy packages to Nexus staging area - automatic.
2. Deploy from Nexus staging to Maven Central - requires approval.
3. Deploy to GitHub - requires approval.

All Java APIs share a staging area, so occasionally repositories are left in the staging area as a results of a possible cancellation or an unwanted pipeline termination, etc. This sometimes causes the deployment to staging to fail. In this case, it is the best to login to the Nexus staging area and manually drop all unwanted repositories and rerun the deployment process.