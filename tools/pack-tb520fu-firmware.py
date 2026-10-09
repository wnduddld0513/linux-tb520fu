#!/usr/bin/env python3
"""Pack locally owned TB520FU hardware dependencies; never publish blobs."""
import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path
import tarfile
import subprocess
import tempfile
from tb520fu_fat import FAT

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stock-root', type=Path, required=True,
                        help='Stock dump root containing vendor/firmware')
    parser.add_argument('--image-dir', type=Path, required=True,
                        help='Stock image directory containing NON-HLOS.bin, BTFM.bin and dspso.bin')
    parser.add_argument('--output', type=Path,
                        default=ROOT / 'build_files/firmware-lenovo-tb520fu.tar.gz')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'tb520fu/firmware-manifest.json').read_text())
    for name, info in manifest['images'].items():
        path = args.image_dir / name
        if path.stat().st_size != info['size'] or hashlib.sha256(path.read_bytes()).hexdigest() != info['sha256']:
            raise SystemExit(f'{path}: differs from the documented stock firmware')
    images = {n: FAT(args.image_dir / n) for n in ('NON-HLOS.bin', 'BTFM.bin')}
    indices = {n: {p: (c, s) for p, c, s in fs.walk()} for n, fs in images.items()}
    entries = []
    with tempfile.TemporaryDirectory(prefix='tb520fu-dsp-') as tmp:
        # debugfs is read-only without -w. Only the temporary host directory is written.
        subprocess.run(['debugfs', '-R', f'rdump /adsp {tmp}',
                        str(args.image_dir / 'dspso.bin')], check=True)
        for key, info in manifest['files'].items():
            source = info['source']
            if ':' in source:
                image, name = source.split(':', 1)
                if image == 'dspso.bin':
                    payload = (Path(tmp) / name).read_bytes()
                else:
                    cluster, size = indices[image][name]
                    payload = images[image].chain(cluster)[:size]
            else:
                payload = (args.stock_root / source).read_bytes()
            if hashlib.sha256(payload).hexdigest() != info['sha256'] or len(payload) != info['size']:
                raise SystemExit(f'{source}: differs from the documented stock dump')
            entries.append((info['destination'], payload))
    if len({name for name, _ in entries}) != len(entries):
        raise SystemExit('Duplicate destination in manifest')
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
