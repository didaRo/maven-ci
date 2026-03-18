# Spring Boot actuator example

This sample is the witness consumer for the GitLab catalog components and the GitHub reference workflows.
Its job is to validate the templates end to end and catch regressions on a real Maven project.

It demonstrates:

- Spring Boot `4.0.3`
- Java `25` by default
- unit tests and integration tests
- JaCoCo coverage
- Sonar-ready configuration
- OWASP dependency-check profile
- snapshot and release automation

This project stays under `examples/` because it is only a witness consumer.
It is not the main deliverable of the repository.

## Local commands

Build:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp clean verify
```

Build with Java 21 locally:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp -Djava.version=21 clean verify
```

Security profile:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp -Psecurity clean verify
```

Release dry run:

```bash
mvn -f examples/spring-boot-actuator/pom.xml -B -ntp release:clean release:prepare -DdryRun=true
```
