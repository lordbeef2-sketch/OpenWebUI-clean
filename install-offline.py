#!/usr/bin/env python3
# Strictly-offline installer (NO UPGRADES). Installs Python wheels ONE-BY-ONE
# and npm archives individually, all from local folders you choose.

import argparse, os, shutil, subprocess, sys
from pathlib import Path

def ask_path(label, default: Path) -> Path:
    raw = input(f"{label} [{default}]: ").strip()
    return (Path(raw) if raw else default).expanduser().resolve()

def run(cmd, cwd=None, env=None):
    print("==>", " ".join(str(c) for c in cmd))
    subprocess.check_call(cmd, cwd=str(cwd) if cwd else None, env=env)

def py_in_venv(venv: Path) -> Path:
    return venv / ("Scripts/python.exe" if os.name == "nt" else "bin/python")

def ensure_venv(venv: Path) -> Path:
    if not venv.exists():
        print(f"== Creating virtualenv at: {venv}")
        run([sys.executable, "-m", "venv", str(venv)])
    else:
        print(f"== Using existing virtualenv: {venv}")
    py = py_in_venv(venv)
    if not py.exists():
        raise RuntimeError(f"Python interpreter not found in venv: {py}")
    return py

def collect(folder: Path, exts):
    out = []
    if folder.exists():
        for ext in exts: out += sorted(folder.glob(f"*{ext}"))
    return out

def main():
    repo_root = Path(__file__).resolve().parent
    ap = argparse.ArgumentParser("Strictly-offline Python+npm installer (per-wheel)")
    ap.add_argument("--venv", type=Path, default=repo_root/".venv")
    ap.add_argument("--wheels", type=Path, default=repo_root/"offline_bundle"/"python_wheels")
    ap.add_argument("--npm", type=Path, default=repo_root/"offline_bundle"/"npm")
    ap.add_argument("--project", type=Path, default=repo_root)
    ap.add_argument("--yes","-y", action="store_true", help="non-interactive")
    ap.add_argument("--pip-no-deps", action="store_true",
                    help="install wheels without resolving deps (fast, but you must include all deps manually)")
    args = ap.parse_args()

    if not args.yes:
        venv_dir   = ask_path("Virtualenv directory", args.venv)
        wheels_dir = ask_path("Folder with Python wheels (*.whl)", args.wheels)
        npm_dir    = ask_path("Folder with npm archives (*.tgz|*.tar|*.zip)", args.npm)
        project    = ask_path("Project folder (package.json)", args.project)
    else:
        venv_dir, wheels_dir, npm_dir, project = args.venv, args.wheels, args.npm, args.project

    print("\n== Config ==")
    print("venv:    ", venv_dir)
    print("wheels:  ", wheels_dir)
    print("npm:     ", npm_dir)
    print("project: ", project, "\n")

    if not project.exists():
        raise SystemExit(f"[ERROR] Project folder not found: {project}")

    # Strict offline envs
    base_env = os.environ.copy()
    for k in ("HTTP_PROXY","HTTPS_PROXY","ALL_PROXY","NO_PROXY"):
        base_env.pop(k, None)

    env_pip = base_env.copy()
    env_pip.update({
        "PIP_NO_INDEX":"1",
        "PIP_DISABLE_PIP_VERSION_CHECK":"1",
        "PIP_DEFAULT_TIMEOUT":"1",
        "PIP_INDEX_URL":"", "PIP_EXTRA_INDEX_URL":"", "PIP_TRUSTED_HOST":""
    })

    env_npm = base_env.copy()
    env_npm.update({
        "npm_config_proxy":"", "npm_config_https_proxy":"",
        "npm_config_registry":"file:.",
        "npm_config_audit":"false", "npm_config_fund":"false",
        "npm_config_fetch_retries":"0", "npm_config_offline":"true"
    })

    # 1) venv
    py = ensure_venv(venv_dir)

    # 2) Python wheels — ONE BY ONE
    if not wheels_dir.exists():
        print(f"!! Wheel directory not found: {wheels_dir}")
    else:
        wheels = collect(wheels_dir, [".whl"])
        if not wheels:
            print(f"!! No *.whl files in {wheels_dir}")
        else:
            print(f"== Installing {len(wheels)} wheel(s) individually from {wheels_dir} ==")
            for i, whl in enumerate(wheels, 1):
                print(f"-- [{i}/{len(wheels)}] {whl.name}")
                cmd = [str(py), "-m", "pip", "install",
                       "--no-index", "--find-links", str(wheels_dir), str(whl)]
                if args.pip_no_deps:
                    cmd.insert( cmd.index("install")+1, "--no-deps")
                run(cmd, env=env_pip)

    # 3) npm archives — one by one (already was)
    if not npm_dir.exists():
        print(f"!! NPM directory not found: {npm_dir}")
    else:
        archives = collect(npm_dir, [".tgz",".tar",".zip"])
        if not archives:
            print(f"!! No npm archives (*.tgz|*.tar|*.zip) in {npm_dir}")
        else:
            pkg_json = project/"package.json"
            if not pkg_json.exists():
                print("!! No package.json found. Creating a minimal one.")
                pkg_json.write_text('{"name":"offline-local","version":"1.0.0"}', encoding="utf-8")
            (project/"node_modules").mkdir(exist_ok=True)

            npm = shutil.which("npm")
            if not npm:
                raise SystemExit("[ERROR] 'npm' not found on PATH.")

            print(f"== Installing {len(archives)} npm archive(s) individually from {npm_dir} ==")
            for i, arc in enumerate(archives, 1):
                print(f"-- [{i}/{len(archives)}] {arc.name}")
                run([npm, "install",
                     "--prefer-offline", "--no-audit", "--no-fund", "--legacy-peer-deps",
                     str(arc)], cwd=project, env=env_npm)

    print("\n== Offline install complete (per-wheel, no upgrades) ==")

if __name__ == "__main__":
    try: main()
    except subprocess.CalledProcessError as e:
        print(f"\n[ERROR] Command failed with exit code {e.returncode}"); sys.exit(e.returncode)
    except Exception as ex:
        print(f"\n[ERROR] {ex}"); sys.exit(1)
