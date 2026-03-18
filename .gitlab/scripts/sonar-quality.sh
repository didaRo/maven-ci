#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

if [ "${ENABLE_SONAR:-false}" != "true" ]; then
  echo "Sonar skipped because ENABLE_SONAR=false."
  exit 0
fi

if [ -z "${SONAR_PROJECT_KEY:-}" ] || [ -z "${SONAR_TOKEN:-}" ]; then
  echo "Sonar skipped. Configure SONAR_PROJECT_KEY and SONAR_TOKEN to enable it."
  exit 0
fi

sonar_host_url="${SONAR_HOST_URL:-https://sonarcloud.io}"

gitlab_component::load_maven_cli_args
sonar_args=(
  "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}"
  -f "$PROJECT_DIR/pom.xml"
  -DskipTests
  -Dsonar.host.url="$sonar_host_url"
  -Dsonar.projectKey="$SONAR_PROJECT_KEY"
)

if [ -n "${SONAR_ORGANIZATION:-}" ]; then
  sonar_args+=("-Dsonar.organization=$SONAR_ORGANIZATION")
fi

if gitlab_component::run_with_optional_failure "${SONAR_ALLOW_FAILURE:-false}" "$MVN" "${sonar_args[@]}" sonar:sonar; then
  exit 0
fi

if [ "${SONAR_ALLOW_FAILURE:-false}" = "true" ]; then
  echo "Sonar failed but SONAR_ALLOW_FAILURE=true, continuing."
  exit 0
fi

exit 1
