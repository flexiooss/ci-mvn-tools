#!/usr/bin/env bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

if [ -z ${VERSION} ]; then
    export VERSION=$(flexio-flow version)
fi

echo "Building version ${VERSION}"

if [ -z ${WORKSPACE} ]; then
  cp ~/.m2/settings.xml $SCRIPT_DIR/settings.xml
else
  cp $WORKSPACE/secrets/settings.xml $SCRIPT_DIR/settings.xml
fi

CI_TOOLS_IMAGE_VERSION=$VERSION docker-compose -f docker-compose-build.yml build

rm -f $SCRIPT_DIR/settings.xml