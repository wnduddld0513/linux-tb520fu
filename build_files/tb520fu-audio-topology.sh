#!/bin/bash
# Called by a future image build only. Not executed during source porting.
set -euo pipefail
upstream=https://git.codelinaro.org/linaro/qcomlt/audioreach-topology.git
commit=1d4c4e337df6bad4d52c4f7b3e15fff3f485be62
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
git -C "$work" init -q
git -C "$work" fetch -q --depth=1 "$upstream" "$commit"
git -C "$work" checkout -q --detach FETCH_HEAD
[ "$(git -C "$work" rev-parse HEAD)" = "$commit" ]
m4 -I "$work" -I /ctx/audio_topology /ctx/audio_topology/SM8650-TB520FU.m4 > "$work/TB520FU.conf"
alsatplg -c "$work/TB520FU.conf" -o "$work/TB520FU-tplg.bin"
install -Dpm0644 "$work/TB520FU-tplg.bin" /usr/lib/firmware/qcom/sm8650/Lenovo-Yoga-TB520FU-tplg.bin
