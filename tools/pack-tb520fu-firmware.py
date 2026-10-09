#!/usr/bin/env python3
"""Pack locally owned TB520FU display/touch dependencies; never publish blobs."""
import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path
import tarfile

ROOT = Path(__file__).resolve().parents[1]
PREFIX = 'usr/lib/firmware/qcom/sm8650/lenovo/tb520fu/'
FILES = {
    'novatek_ts_tianma_fw.bin': PREFIX + 'novatek_ts_tianma_fw.bin',
    'novatek_ts_boe_fw.bin': PREFIX + 'novatek_ts_boe_fw.bin',
    'gen70900_zap.mbn': PREFIX + 'gen70900_zap.mbn',
    'gen70900_sqe.fw': 'usr/lib/firmware/qcom/gen70900_sqe.fw',
    'gmu_gen70900.bin': 'usr/lib/firmware/qcom/gmu_gen70900.bin',
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stock-root', type=Path, required=True,
                        help='Stock dump root containing vendor/firmware')
    parser.add_argument('--output', type=Path,
                        default=ROOT / 'build_files/firmware-lenovo-tb520fu.tar.gz')
    args = parser.parse_args()
    known = json.loads((ROOT / 'tb520fu/firmware-manifest.json').read_text())['files']
    entries = []
    for source, destination in FILES.items():
        path = args.stock_root / 'vendor/firmware' / source
        payload = path.read_bytes()
        digest = hashlib.sha256(payload).hexdigest()
        if digest != known[source]['sha256'] or len(payload) != known[source]['size']:
            raise SystemExit(f'{path}: differs from the documented stock dump; review manifest first')
        entries.append((destination, payload))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # Stable output: source timestamps, uid and gzip filename never enter archive.
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode='w', format=tarfile.USTAR_FORMAT) as archive:
        for destination, payload in sorted(entries):
            entry = tarfile.TarInfo(destination)
            entry.size = len(payload)
            entry.mode = 0o644
            entry.mtime = 0
            archive.addfile(entry, io.BytesIO(payload))
    args.output.write_bytes(gzip.compress(buffer.getvalue(), mtime=0))
    digest = hashlib.sha256(args.output.read_bytes()).hexdigest()
    args.output.with_name(args.output.name + '.sha256').write_text(f'{digest}  {args.output.name}\n')
    print(f'Packed {len(entries)} firmware files: {args.output}')
    print(f'SHA256: {digest}')

if __name__ == '__main__':
    main()
