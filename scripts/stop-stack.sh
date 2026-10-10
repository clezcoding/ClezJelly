#!/usr/bin/env bash
# Stop the stack. Same as: ./install.sh down
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )" || exit 1
exec ./install.sh down
