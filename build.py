#!/usr/bin/env python3
from pathlib import Path
import shutil
import subprocess

# Find directories
root_dir = Path(__file__).parent
asm_dir = root_dir / 'asm'
build_dir = root_dir / 'build'
build_dir.mkdir(exist_ok=True)

# Verify customasm is installed
if shutil.which('customasm') is None:
    raise RuntimeError('customasm not present on PATH. You can install it with `cargo install customasm`')

# Run customasm on every asm file.
for input_path in asm_dir.glob('**/*.asm'):
    output_path = build_dir / (input_path.stem + '.out')
    hex_path = build_dir / (input_path.stem + '.hex')
    print(f'Assembling {output_path}')
    subprocess.run([
        'customasm', 
        input_path, 
        '-q',
        '-f', 'annotated,base:16,group:4',
        '-o', output_path,
        '--',
        '-f', 'intelhex',
        '-o', hex_path,
    ])
