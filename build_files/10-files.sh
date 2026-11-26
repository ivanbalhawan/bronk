#!/bin/bash
# Copy the contents of system_files/ of the git repo to /. Runs first, because
# the later scripts use these files.

set -ouex pipefail

cp -avf "/ctx/system_files"/. /
