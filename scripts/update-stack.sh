#!/usr/bin/env bash
# Pull newer images and recreate changed containers. Same as: ./install.sh update
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )" || exit 1
exec ./install.sh update
