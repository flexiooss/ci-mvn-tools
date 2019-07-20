#!/usr/bin/env bash

if [ -z ${VERSION} ]; then
    export VERSION=$(flexio-flow version)
fi

echo "Building version ${VERSION}"

docker-compose -f docker-compose-build.yml build
