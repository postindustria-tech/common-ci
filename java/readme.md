# Java Specific CI/CD Approach
This API complies with the `common-ci` approach.

## Code Signing
We use Maven to package our Java APIs. The process of signing the result packages for Maven is different from Dotnet signing process.
1. The signing process for Java uses `PGP ASCII Armored File` with file extension `.asc` instead of `.pfx` as in Dotnet.
2. The process requires the `.asc` file to be imported using `gpg`.
3. Then the result package will be signed as part of Maven `install` process using `maven-gpg-plugin`.