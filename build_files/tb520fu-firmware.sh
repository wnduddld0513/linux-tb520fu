#!/bin/bash
# Install local stock TB520FU touch/GPU dependencies. No remote fallback.
set -euo pipefail
archive=/ctx/build_files/firmware-lenovo-tb520fu.tar.gz
checksum=${archive}.sha256
if [[ ! -f ${archive} || ! -f ${checksum} ]]; then
    echo 'TB520FU firmware missing: run tools/pack-tb520fu-firmware.py --stock-root <dump> before creating an image.' >&2
    exit 1
fi
(cd /ctx/build_files && sha256sum -c "${checksum}")
python3 - "${archive}" <<'PY'
import hashlib
import json
from pathlib import Path, PurePosixPath
import sys
import tarfile

manifest = json.loads(Path('/ctx/tb520fu/firmware-manifest.json').read_text())['files']
expected = {v['destination']: v for v in manifest.values()}
with tarfile.open(sys.argv[1], 'r:gz') as archive:
    members = archive.getmembers()
    names = [m.name for m in members]
    if len(names) != len(set(names)) or set(names) != set(expected):
        raise SystemExit('Firmware archive must contain exactly the documented files')
    checked = []
    for member in members:
        if not member.isfile() or member.size != expected[member.name]['size']:
            raise SystemExit('Invalid firmware member: ' + member.name)
        path = PurePosixPath(member.name)
        if path.is_absolute() or '..' in path.parts:
            raise SystemExit('Invalid archive path')
        payload = archive.extractfile(member).read()
        if hashlib.sha256(payload).hexdigest() != expected[member.name]['sha256']:
            raise SystemExit('Firmware hash mismatch: ' + member.name)
        checked.append((member.name, payload))
# Validate everything before writing; retain generic GPU firmware from linux-firmware.
for name, payload in checked:
    target = Path('/') / name
    if name in ('usr/lib/firmware/qcom/gen70900_sqe.fw',
                'usr/lib/firmware/qcom/gmu_gen70900.bin') and (
                target.exists() or target.with_suffix(target.suffix + '.zst').exists() or
                target.with_suffix(target.suffix + '.xz').exists()):
        continue
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(payload)
    target.chmod(0o644)
PY
