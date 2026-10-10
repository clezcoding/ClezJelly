#!/usr/bin/env bash
# Health of every service. Same as: ./install.sh status
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )" || exit 1
exec ./install.sh status
