#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap.sh
. "$SCRIPT_DIR/bootstrap.sh"

GITLAB_COMPONENT_MAVEN_CLI_ARGS=()

gitlab_component::load_maven_cli_args() {
  GITLAB_COMPONENT_MAVEN_CLI_ARGS=()
  if [ -n "${MAVEN_CLI_OPTS:-}" ]; then
    read -r -a GITLAB_COMPONENT_MAVEN_CLI_ARGS <<< "${MAVEN_CLI_OPTS}"
  fi
}

gitlab_component::project_version() {
  gitlab_component::load_maven_cli_args
  "$MVN" -q -DforceStdout "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" help:evaluate -Dexpression=project.version | tail -n 1
}

gitlab_component::ensure_snapshot_version() {
  local current_version
  current_version="$(gitlab_component::project_version)"
  case "$current_version" in
    *-SNAPSHOT)
      printf '%s\n' "$current_version"
      ;;
    *)
      echo "Current version $current_version is not a SNAPSHOT. Nothing to publish."
      exit 0
      ;;
  esac
}

gitlab_component::run_with_optional_failure() {
  local allow_failure="$1"
  shift

  set +e
  "$@"
  local status=$?
  set -e

  if [ $status -ne 0 ] && [ "$allow_failure" = "true" ]; then
    echo "Command failed but optional failure is enabled, continuing."
    return 0
  fi

  return $status
}

gitlab_component::compute_next_snapshot_version() {
  local release_version="$1"
  gitlab_component::load_maven_cli_args

  local release_major release_minor release_next_incremental
  release_major=$("$MVN" -q -DforceStdout "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" build-helper:parse-version "-DversionString=$release_version" help:evaluate -Dexpression=parsedVersion.majorVersion | tail -n 1)
  release_minor=$("$MVN" -q -DforceStdout "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" build-helper:parse-version "-DversionString=$release_version" help:evaluate -Dexpression=parsedVersion.minorVersion | tail -n 1)
  release_next_incremental=$("$MVN" -q -DforceStdout "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" build-helper:parse-version "-DversionString=$release_version" help:evaluate -Dexpression=parsedVersion.nextIncrementalVersion | tail -n 1)
  printf '%s.%s.%s-SNAPSHOT\n' "$release_major" "$release_minor" "$release_next_incremental"
}
