#!/bin/bash
# The wrapper and the compiler are generated into the same repository, so the compiler is found relative to this
# script's location. The path stays relative to the execution root because gcc would otherwise write absolute header
# paths that bazel rejects as undeclared inclusions.
set -euo pipefail
exec "$(dirname "${BASH_SOURCE[0]}")/../bin/%{real_binary}%" "$@" %{extra_args}%
