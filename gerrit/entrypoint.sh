#!/bin/bash

set -e

# Set permissions for Gerrit site
# chown -R "$(id -u):$(id -g)" "$DOCKER_GERRIT_SITE"

# Start Gerrit
exec java -jar "$DOCKER_GERRIT_HOME/gerrit.war" daemon -d "$DOCKER_GERRIT_SITE"
