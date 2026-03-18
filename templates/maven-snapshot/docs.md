# Maven Snapshot Publish

Low-level snapshot component.

It provides:

- automatic snapshot publication on story branches
- manual snapshot publication
- deploy with `-DskipTests`

Example:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-group/maven-catalog/maven-snapshot@1.0.0
    inputs:
      project_dir: .
```

Required runtime value:

- `MAVEN_SETTINGS_XML`

Defaults:

- automatic snapshot enabled
- manual snapshot enabled
- story branch regex `^US[0-9][A-Za-z0-9._/-]*$`
