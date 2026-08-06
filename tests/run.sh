#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

find "$repo_root/RealisticBookPages/42/media/lua" -type f -name '*.lua' -exec luac -p {} \;
lua "$repo_root/tests/test_config.lua" "$repo_root"
lua "$repo_root/tests/test_sandbox.lua" "$repo_root"
lua "$repo_root/tests/test_reading_effects.lua" "$repo_root"
