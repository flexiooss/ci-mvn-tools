#!/usr/bin/env bash

UTILITIES=/usr/local/lib/poom-ci-notifiers.jar
CLASS=org.codingmatters.poom.ci.apps.notifiers.ImageBuiltNotification

java -cp $UTILITIES $CLASS "$@"