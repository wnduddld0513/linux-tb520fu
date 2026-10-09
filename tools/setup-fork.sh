#!/usr/bin/env bash
# Reapply fork-only settings after cloning this branch in WSL.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
git rev-parse --git-dir >/dev/null
if [[ "$(git branch --show-current)" != tb520fu ]]; then
    echo "Switch to the tb520fu branch before running this script." >&2
    exit 1
fi
fork_url=https://github.com/wnduddld0513/linux-tb520fu.git
if ! git remote | grep -qx origin; then
    git remote add origin "$fork_url"
fi
git config --local --replace-all remote.origin.url "$fork_url"
git config --local --replace-all remote.origin.pushurl "$fork_url"
git config --local --replace-all remote.origin.push refs/heads/tb520fu:refs/heads/tb520fu
git config --local remote.origin.mirror false
git config --local remote.pushDefault origin
git config --local push.default simple
git config --local push.followTags false
git config --local branch.tb520fu.remote origin
git config --local branch.tb520fu.merge refs/heads/tb520fu
git config --local branch.tb520fu.pushRemote origin
# gh also needs an explicit fork default when creating PRs from a fork.
git config --local remote.origin.gh-resolved base
chmod +x .githooks/pre-push
git config --local core.hooksPath .githooks
printf 'Push destination: %s (tb520fu only)\n' "$fork_url"
