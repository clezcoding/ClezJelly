#!/usr/bin/env bash
# Start the stack (and launch Jellyfin). Same as: ./install.sh up
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )" || exit 1
exec ./install.sh up
