# Maven CI

Recommended default entrypoint.

It wires the full lifecycle in the right order:

1. build and test
2. optional Sonar
3. optional OWASP
4. snapshot publish
5. release

Example:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-group/maven-catalog/maven-ci@1.0.0
    inputs:
      project_dir: .
```

For most projects, the defaults are enough.
Typical overrides are only:

- `project_dir`
- `runner_tags`
- `enable_sonar`
- `snapshot_branch_regex`

Expected runtime values:

- `MAVEN_SETTINGS_XML`
- `RELEASE_PUSH_TOKEN`
- optional Sonar and OWASP secrets
