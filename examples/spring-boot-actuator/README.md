# Spring Boot actuator example

This sample is the reference project for the GitHub CI/CD component.

It demonstrates:

- Spring Boot `4.0.3`
- Java `25` by default
- unit tests with Surefire
- integration tests with Failsafe
- JaCoCo coverage reporting
- SonarQube Cloud ready configuration
- OWASP dependency-check profile
- snapshot and release publication to GitHub Packages

## Local commands

Build with the default Java target:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp clean verify
```

If your local machine only has Java 21, you can still validate the sample with:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp -Djava.version=21 clean verify
```

Run OWASP locally:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp -Psecurity clean verify
```

Dry-run a release:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp release:clean release:prepare -DdryRun=true
```

## Release conventions

- release version example: `1.0.0`
- Git tag example: `1.0.0`
- no `v` prefix is used for the release tag
