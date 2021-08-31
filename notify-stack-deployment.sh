#!/usr/bin/env bash

UTILITIES=/usr/local/lib/poom-ci-notifiers.jar
CLASS=org.codingmatters.poom.ci.apps.notifiers.StackDeploymentNotifier

java -cp $UTILITIES $CLASS "$@"