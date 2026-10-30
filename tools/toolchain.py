#!/usr/bin/env python3
"""Inspect prerequisites or fetch the exact framework revision in toolchain.json."""
import argparse
import importlib.util
import json
import shutil
import subprocess
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('command',choices=['check','fetch','patch']);a=ap.parse_args()
    lock=json.loads((ROOT/'toolchain.json').read_text())['xboxrecomp'];dest=ROOT/'third_party/xboxrecomp'
    patch=ROOT/'patches/xboxrecomp-linux.patch'
    def apply_local_patch(repo):
        head=subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip()
        if head!=lock['revision']:raise ValueError(f'checkout is {head}; expected {lock["revision"]}; refusing local patch')
        if not patch.is_file():raise ValueError(f'local patch is missing: {patch}')
        reverse=subprocess.run(['git','-C',str(repo),'apply','--reverse','--check',str(patch)],capture_output=True)
        if reverse.returncode==0:
            print('Project runtime patch is already applied');return
        forward=subprocess.run(['git','-C',str(repo),'apply','--check',str(patch)],capture_output=True,text=True)
        if forward.returncode:
            raise ValueError('local patch does not apply cleanly; inspect vendor changes before proceeding')
        subprocess.run(['git','-C',str(repo),'apply',str(patch)],check=True)
        print(f'Applied project runtime patch from {patch}')
    if a.command=='patch':
        if not dest.is_dir():raise ValueError('framework checkout missing; run fetch first')
        apply_local_patch(dest);return
    if a.command=='fetch':
        if dest.exists():
            head=subprocess.check_output(['git','-C',str(dest),'rev-parse','HEAD'],text=True).strip()
            if head!=lock['revision']:raise ValueError(f'existing checkout is {head}; expected {lock["revision"]}; not modifying it')
            print(f'Already at {head}');apply_local_patch(dest);return
        # A failed fetch is left in a clearly named staging directory, never treated as installed.
        staging=dest.with_name('xboxrecomp.partial')
        if staging.exists():raise ValueError(f'prior incomplete fetch at {staging}; inspect it before retrying')
        staging.mkdir(parents=True)
        subprocess.run(['git','init',str(staging)],check=True)
        subprocess.run(['git','-C',str(staging),'remote','add','origin',lock['repository']],check=True)
        subprocess.run(['git','-C',str(staging),'fetch','--depth','1','origin',lock['revision']],check=True)
        subprocess.run(['git','-C',str(staging),'checkout','--detach','FETCH_HEAD'],check=True)
        head=subprocess.check_output(['git','-C',str(staging),'rev-parse','HEAD'],text=True).strip()
        if head!=lock['revision']:raise ValueError('fetched revision mismatch')
        staging.rename(dest);print(f'Installed {head} at {dest}');apply_local_patch(dest);return
    result={'executables':{x:shutil.which(x) for x in ['git','cmake','ninja','cc','clang','pkg-config','objdump','xemu']},
            'python_capstone':importlib.util.find_spec('capstone') is not None,
            'framework_checkout':str(dest) if dest.is_dir() else None,'framework_expected_revision':lock['revision'],
            'packages':{},'scope':'Environment probe only; no claim of a build or game compatibility.'}
    if shutil.which('pkg-config'):
        for package in ['sdl2','epoxy','openssl','libavcodec','libavformat','libavutil','libswscale']:
            proc=subprocess.run(['pkg-config','--modversion',package],capture_output=True,text=True)
            result['packages'][package]=proc.stdout.strip() if proc.returncode==0 else None
    (ROOT/'reports').mkdir(exist_ok=True)
    (ROOT/'reports/toolchain-preflight.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
    required=['git','cmake','ninja','cc','pkg-config']
    if not all(result['executables'][x] for x in required) or not result['framework_checkout'] or not result['python_capstone'] or not result['packages'] or not all(result['packages'].values()):return 1
    return 0
if __name__=='__main__':
    try:sys.exit(main())
    except (OSError,ValueError,subprocess.CalledProcessError) as e:print(f'ERROR: {e}',file=sys.stderr);sys.exit(1)
