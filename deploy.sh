#!/usr/bin/env bash
if [ -z ${VERSION} ]; then
    export VERSION=$(flexio-flow version)
fi

echo "Deploying version ${VERSION}"

docker-compose -f docker-compose-build.yml --log-level INFO push