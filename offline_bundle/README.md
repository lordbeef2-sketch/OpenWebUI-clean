offline_bundle/README
=====================

Purpose
-------
This folder contains the offline dependency artifacts for the project and a very small installer script:

- `python_wheels/` — Python wheels and sdists downloaded for offline installation.
- `npm/` — npm package tarballs (`.tgz`) collected for offline use.
- `install-offline.ps1` — a simple PowerShell script that:
  - creates or reuses a virtualenv at the project root (`.venv`),
  - upgrades pip/setuptools/wheel in the venv,
  - installs Python requirements using `offline_bundle/python_wheels` when present (falls back to PyPI if not),
  - runs `npm install --force` in the repository root.

This README documents how to run the script and a few troubleshooting tips.

Prerequisites
-------------
- Windows PowerShell (pwsh).
- Python 3.11+ available on PATH as `python` or `py`.
- Node & npm installed and on PATH.
- Recommended: run from the repository root. The script is located at `offline_bundle\install-offline.ps1`.

How to run
----------
Open PowerShell from the repository root (C:\sand\fresh\open-webui) and run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\offline_bundle\install-offline.ps1
```

What the script does (summary)
-----------------------------
1. Ensures a virtual environment exists at `.venv` (creates it if missing).
2. Upgrades pip/setuptools/wheel inside the `.venv`.
3. For each requirements file found (`requirements.txt`, `requirements1.txt`, `backend\requirements.txt`) it will:
   - install using `pip install --no-index --find-links offline_bundle\python_wheels -r <requirements>` when `offline_bundle\python_wheels` exists, or
   - install from PyPI (online) if `offline_bundle\python_wheels` is not present.
4. Runs `npm install --force` in the repository root.

Notes and safe defaults
-----------------------
- The script is intentionally simple and uses `npm install --force` as you requested. `--force` can override dependency resolution problems but may install an inconsistent tree — run tests afterwards.
- If you prefer a softer npm fallback, replace `--force` with `--legacy-peer-deps` (recommended when encountering peer-dep conflicts).

Troubleshooting
---------------
- "Python not found": ensure `python` or `py` is on PATH, or install Python 3.11+.
- "Wheel not found" errors from pip: make sure `offline_bundle\python_wheels` contains the wheels for the target platform and Python version. If not, run on a machine with network access:

```powershell
# from repository root
pwsh -NoProfile -ExecutionPolicy Bypass
python -m pip download -d offline_bundle\python_wheels -r requirements.txt
python -m pip download -d offline_bundle\python_wheels -r requirements1.txt
python -m pip download -d offline_bundle\python_wheels -r backend\requirements.txt
```

- npm ERESOLVE peer dependency errors: `npm install --force` will attempt to force install. If you prefer to respect peer deps but accept legacy behavior, run:

```powershell
npm install --legacy-peer-deps
```

- If the script logs a pip/npm exit code warning, inspect the console output for the failing command and re-run that command manually to get more detail.

If you want changes
-------------------
- I can make the script stricter (exit on first error), change `npm` flags, or add extra logging to a file. Tell me exactly which change you want and I will make it.

License / authorship
--------------------
This README and the included `install-offline.ps1` were added at your request to help run the offline install flow; they are part of your repository and follow the repo license.
