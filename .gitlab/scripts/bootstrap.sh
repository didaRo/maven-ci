#!/usr/bin/env bash
set -euo pipefail

if [ -f ./mvnw ]; then
  chmod +x ./mvnw
  MVN=./mvnw
else
  MVN=mvn
fi
export MVN

mkdir -p .m2

if [ -n "${MAVEN_SETTINGS_XML:-}" ]; then
  printf '%s\n' "$MAVEN_SETTINGS_XML" > .m2/settings.xml
elif [ -n "${CI_JOB_TOKEN:-}" ]; then
  registry_username="${MAVEN_REGISTRY_USERNAME:-gitlab-ci-token}"
  registry_password="${MAVEN_REGISTRY_PASSWORD:-$CI_JOB_TOKEN}"

  cat > .m2/settings.xml <<EOF
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>${MAVEN_DEPLOY_SERVER_ID}</id>
      <username>${registry_username}</username>
      <password>${registry_password}</password>
    </server>
  </servers>
</settings>
EOF
fi

if [ -f .m2/settings.xml ]; then
  case " ${MAVEN_CLI_OPTS:-} " in
    *" --settings .m2/settings.xml "*) ;;
    *)
      export MAVEN_CLI_OPTS="${MAVEN_CLI_OPTS:-} --settings .m2/settings.xml"
      ;;
  esac
fi
