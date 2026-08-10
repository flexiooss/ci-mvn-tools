#!/usr/bin/env bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

if [ -z "${VERSION}" ]; then
    export VERSION=$(flexio-flow version)
fi

echo "Building version ${VERSION}"

if [ -z "${WORKSPACE}" ]; then
  SETTINGS_SRC=~/.m2/settings.xml
else
  SETTINGS_SRC=$WORKSPACE/secrets/settings.xml
fi
if ! [ -f "${SETTINGS_SRC}" ]; then
  echo "Could not find m2 settings in ${SETTINGS_SRC}."
  exit 1
fi
echo "Using m2 settings from ${SETTINGS_SRC}"
cp "${SETTINGS_SRC}" "${SCRIPT_DIR}/settings.xml"

docker-compose -f docker-compose-build.yml build

rm -f "${SCRIPT_DIR}/settings.xml"