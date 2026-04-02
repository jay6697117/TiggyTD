#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/validate_commit.sh"
bash "$script_dir/validate_push.sh"
bash "$script_dir/validate_assets.sh"
