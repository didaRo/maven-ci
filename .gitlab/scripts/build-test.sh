#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

gitlab_component::load_maven_cli_args
"$MVN" "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" clean verify
