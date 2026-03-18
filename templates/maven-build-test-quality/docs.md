# Maven Build, Test, Quality and Security

Low-level validation component.

It provides:

- `mvn clean verify`
- optional Sonar
- optional OWASP

Example:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-group/maven-catalog/maven-build-test-quality@1.0.0
    inputs:
      project_dir: .
```

Most teams only override:

- `project_dir`
- `runner_tags`
- `enable_sonar`

Optional runtime values:

- `SONAR_PROJECT_KEY`
- `SONAR_TOKEN`
- `SONAR_ORGANIZATION`
- `NVD_API_KEY`
